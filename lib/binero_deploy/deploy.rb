module BineroDeploy
  class Deploy
    def initialize
      @config = Config.parse

      @app = @config.fetch(:app)
      @console = Console.new(prompt: 'Deploy')
      @remote_host = RemoteHost.new(
        host:    @config.fetch(:host),
        app:     @app,
        console: @console
      )
    end

    def start
      @console.info("Starting deploy of #{@app.blue}")
      abort_deploy("You are not on the master branch!") unless on_master_branch?
      abort_deploy("There are uncommitted changes!") if uncommitted_changes?
      abort_deploy("There are unpushed commits!") unless everything_pushed?

      archive_filename = Utils.create_release_name(@app)
      archive_dir = "/tmp"
      create_archive(archive_filepath: "#{archive_dir}/#{archive_filename}")

      release_name = @remote_host.deploy_app(
        archive_filename:    archive_filename,
        local_dir:           archive_dir,
        static_files:        @config.fetch(:static_files),
        keep_releases_count: @config.fetch(:keep_releases)
      )

      @console.success("Release #{release_name.green} deployed!")
      create_release_tag(@app, release_name)
    end

    private

    def uncommitted_changes?
      uncommitted_changes = `git status -s`
      !uncommitted_changes.empty?
    end

    def everything_pushed?
      diff = `git diff --stat origin/master`
      diff.empty?
    end

    def on_master_branch?
      branch_name = `git rev-parse --abbrev-ref HEAD`
      branch_name.strip!
      branch_name == 'master'
    end

    def get_files_to_upload
      exclude = @config.fetch(:exclude)
      exclude_files = exclude.fetch(:files)
      exclude_dirs = exclude.fetch(:dirs)

      repo_files = `git ls-files`.split("\n")
      repo_files -= exclude_files
      repo_files.delete_if do |filename|
        exclude_dirs.any? { |dir| filename =~ /\A#{dir}\/.*/ }
      end
    end

    def create_archive(archive_filepath: filepath)
      @console.info('Archiving files to upload...')
      files = get_files_to_upload
      `tar -cvf #{filepath} #{Shellwords.join(files)}`
      @console.info('Archive created!')
    end

    def create_release_tag(app, release_name)
      @console.info("Creating git release tag...")
      `git tag -a #{release_name} -m 'Deployment of #{app}'`
      @console.info("Pushing release tag to remote...")
      `git push --tags`
    end

    def abort_deploy(message)
      @console.err(message)
      exit 1
    end
  end
end
