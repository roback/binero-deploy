require 'json'

module BineroDeploy
  module Config
    extend self

    CONFIG_FILENAME = 'deploy.json'

    REQUIRED = [
      :host,
      :app,
    ]

    EXCLUDE = {
      files: %w(.gitignore README.md #{CONFIG_FILENAME}),
      dirs: [],
    }
    BACKUP = {
      db: false,
      local_dir: '~',
    }
    DEFAULTS = {
      keep_releases: 10,
      static_files: [],
      exclude: EXCLUDE,
      backup: BACKUP,
    }

    def parse
      abort_config_parse('The deploy config file (#{CONFIG_FILENAME}) does not exist!') unless file_exist?

      config = JSON.parse(File.read(CONFIG_FILENAME), symbolize_names: true)
      config = DEFAULTS.merge(config)

      config[:exclude].merge!(EXCLUDE) { |_,oldval,_| oldval }
      config[:backup].merge!(BACKUP) { |_,oldval,_| oldval }

      abort_config_parse("#{REQUIRED.join(' and ')} must be set in #{CONFIG_FILENAME}") unless REQUIRED.all? { |s| config.key? s }

      config
    end

    private

    def file_exist?
      File.exist?(CONFIG_FILENAME)
    end

    def abort_config_parse(message)
      Console.new(prompt: 'Config').err(message)
      exit 1
    end
  end
end
