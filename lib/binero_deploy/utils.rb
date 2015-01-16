require 'json'

module BineroDeploy
  module Utils
    extend self

    def create_release_name(app_name)
      app_short_name = app_name.split('.').first
      time = formatted_time

      "#{app_short_name}_#{time}"
    end

    def create_backup_name(app_name)
      app_short_name = app_name.split('.').first
      time = formatted_time

      "#{app_short_name}-backup_#{time}.tar.gz"
    end

    private

    def formatted_time
      Time.now.strftime("%Y-%m-%d_%H-%M-%S")
    end
  end
end
