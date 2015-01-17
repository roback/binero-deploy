require 'ruby-progressbar'
require 'net/ssh'
require 'net/scp'

module BineroDeploy
  class RemoteHost
    def initialize(host:, app:, console:)
      config = Net::SSH.configuration_for(host)
      @host = host
      @host_name = config.fetch(:host_name)
      @user = config.fetch(:user)

      @console = console
      @app = app

      @ssh_session = nil
    end


    def deploy_app(archive_filename:, local_dir:, static_files:, keep_releases_count:)
      start_session

      release_name = Utils.create_release_name(@app)
      release_path_full = "#{@app}/data/releases/#{release_name}"
      create_directory(release_path_full)

      local_archive_filepath = "#{local_dir}/#{archive_filename}"
      upload_file(local_archive_filepath, release_path_full)

      extract_files_from_archive(dir: release_path_full, archive_filename: archive_filename)
      remove_file("#{release_path_full}/#{archive_filename}")

      create_symlinks_for_static_files(release_dir: release_path_full, static_files: static_files)
      create_main_symlink_for_release(release_name: release_name)

      remove_old_releases(keep_releases_count)

      end_session

      release_name
    end

    def backup_app(db_enabled:, local_dir:)
      start_session

      archive_filename = Utils.create_backup_name(@app)
      public_dir       = "#{@app}/public_html"
      db_dump          = "db_dump.sql"
      files_to_backup  = [public_dir]

      if db_enabled
        create_database_dump(db_dump)
        files_to_backup << db_dump
      end

      archive_file_count = count_files(public_dir) + (db_enabled ? 1 : 0)
      progressbar = create_progressbar('Archiving files', total: archive_file_count)
      create_backup_archive(archive_filename, files_to_backup) { progressbar.increment }
      progressbar.finish

      download_file(archive_filename, local_dir)

      files_to_remove = [archive_filename]
      files_to_remove << db_dump if db_enabled
      remove_files(files_to_remove)

      end_session

      @console.success("Backup saved to #{File.join(local_dir, archive_filename).green}")
    end

    def setup_app
      start_session

      print_and_abort("#{@app} is already setup on the remote!") if app_is_setup?

      create_directory("#{@app}/data/releases")
      create_directory("#{@app}/data/static")

      release_name = Utils.create_release_name(@app)
      run_command("mv #{@app}/public_html #{@app}/data/releases/#{release_name}")
      create_main_symlink_for_release(release_name: release_name)

      end_session
    end

    def revert_app_to_previous_release
      start_session

      releases = get_releases
      if releases.size > 1
        @console.info("Reverting from #{releases.last.red} to #{releases[-2].green}")
        revert_release_symlink_to(releases[-2])
        remove_release(releases.last)
      else
        print_and_abort("Only one release exists, cannot revert!")
      end

      end_session
    end


    private

    # --------------- DEPLOY ---------------

    def extract_files_from_archive(dir:, archive_filename:)
      run_command("cd #{dir} && tar -xvf #{archive_filename}")
    end

    def create_symlinks_for_static_files(release_dir:, static_files:)
      static_files.each do |static_file|
        filename = static_file.fetch(:filename)
        symlink_filename = static_file.fetch(:symlink_filename, filename)
        relative_path = ('../' * (symlink_filename.count('/') + 2))

        @console.info("Creating symlink for #{symlink_filename}")
        run_command("cd #{release_dir} && ln -s #{relative_path}static/#{filename} #{symlink_filename}")
      end
    end

    def create_main_symlink_for_release(release_name:)
      @console.info("Removing main symlink for old release")
      run_command("rm -f #{@app}/public_html")
      @console.info("Creating main symlink for release #{release_name.green}")
      run_command("cd #{@app} && ln -s ./data/releases/#{release_name} public_html")
    end

    def remove_file(file)
      run_command("rm #{file}")
    end


    # --------------- BACKUP ---------------

    def create_database_dump(dump_filename)
      db_config = parse_db_backup_config_file

      db_host     = db_config.fetch(:db_host)
      db_user     = db_config.fetch(:db_user)
      db_password = db_config.fetch(:db_password)
      db_name     = db_config.fetch(:db_name)

      @console.info("Creating database dump...")
      run_command("mysqldump -h #{db_host} -u #{db_user} -p'#{db_password}' #{db_name} > #{dump_filename}")
      @console.info("Database dump created!")
    end

    def parse_db_backup_config_file
      db_config_json = run_command("cat #{@app}/data/db-backup-config.json").fetch(:stdout)
      begin
        return JSON.parse(db_config_json, symbolize_names: true)
      rescue JSON::ParserError
        print_and_abort("Error when reading database connection config file!")
      end
    end

    def create_backup_archive(archive_filename, files_and_folders)
      command = "tar -czhvf #{archive_filename} #{files_and_folders.join(' ')}"
      run_command(command) { yield }
    end

    def remove_files(files)
      run_command("rm #{files.join(' ')}")
    end

    def count_files(dir)
      run_command("find -L #{dir} | wc -l").fetch(:stdout).to_i
    end


    # --------------- REVERT ---------------

    def revert_release_symlink_to(release)
      run_command("rm #{@app}/public_html")
      run_command("cd #{@app} && ln -s ./data/releases/#{release} public_html")
    end

    # --------------- SETUP ---------------

    def app_is_setup?
      # Tests whether the public directory of the app is a symlink already
      command_result = exec!("test -L #{@app}/public_html")
      command_result[:exit_code] == 0
    end


    # --------------- COMMON ---------------

    def create_directory(dirname, parents: false)
      parents_flag = parents ? "-p" : ""
      run_command("mkdir #{parents_flag} #{dirname}")
    end

    def remove_old_releases(keep_count)
      releases = get_releases.reverse
      releases.slice!(0, keep_count)
      releases.each do |release|
        remove_release(release)
      end
    end

    def get_releases
      releases = run_command("ls #{@app}/data/releases").fetch(:stdout)
      releases = releases.split

      releases.sort
    end

    def remove_release(release)
      @console.info("Removing release #{release.red}")
      run_command("rm -rf #{@app}/data/releases/#{release}")
    end

    # --------------- UTILITYS ---------------

    def download_file(remote_file, local_file)
      pb = create_progressbar('Downloading backup')
      Net::SCP.download!(@host_name, @user, remote_file, local_file) do |ch, name, sent, total|
        pb.total = total
        pb.progress = sent
      end
      pb.finish
    end

    def upload_file(local_file, remote_file)
      pb = create_progressbar('Uploading release')
      Net::SCP.upload!(@host_name, @user, local_file, remote_file) do |ch, name, sent, total|
        pb.total = total
        pb.progress = sent
      end
      pb.finish
    end

    def run_command(command, &callback)
      result = exec!(command, &callback)
      unless result.fetch(:exit_code) == 0
        @console.err("Command failed: #{command}")
        @console.err("Exit code:      #{result.fetch(:exit_code)}")
        @console.err("Stdout:         #{result.fetch(:stdout)}")
        @console.err("Stderr:         #{result.fetch(:stderr)}")
        abort('Failed to execute command, aborting...')
      end
      result
    end

    def exec!(command, &callback)
      stdout_data = ""
      stderr_data = ""
      exit_code = nil
      exit_signal = nil
      @ssh_session.open_channel do |channel|
        channel.exec(command) do |ch, success|
          unless success
            abort! "FAILED: couldn't execute command (ssh.channel.exec)"
          end
          channel.on_data do |ch,data|
            callback.call(data) if callback
            stdout_data+=data
          end

          channel.on_extended_data do |ch,type,data|
            stderr_data+=data
          end

          channel.on_request("exit-status") do |ch,data|
            exit_code = data.read_long
          end

          channel.on_request("exit-signal") do |ch, data|
            exit_signal = data.read_long
          end
        end
      end
      @ssh_session.loop
      {
        stdout: stdout_data,
        stderr: stderr_data,
        exit_code: exit_code,
        exit_signal: exit_signal
      }
    end

    def create_progressbar(title, total: nil)
      if total.nil?
        ProgressBar.create(
          format:         '%t |%B| %p%%',
          progress_mark:  '=',
          remainder_mark: ' ',
          title:          title,
        )
      else
        ProgressBar.create(
          format:         '%t %c/%C |%B| %p%%',
          progress_mark:  '=',
          remainder_mark: ' ',
          title:          title,
          total:          total,
        )
      end
    end

    def print_and_abort(message)
      @console.err(message)
      @ssh_session.close unless @ssh_session.nil?
      exit 1
    end

    def start_session
      @ssh_session = Net::SSH.start(@host_name, @user)
    end

    def end_session
      @ssh_session.close
    end
  end
end
