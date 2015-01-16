require 'thor'
require 'binero_deploy'

module BineroDeploy
  class Cli < Thor
    desc "deploy", "Deploy the website to binero, creating a new release."
    def deploy
      Deploy.new.start
    end

    desc "backup", "Backup the website and download a .tar.gz archive of it."
    def backup
      Backup.new.start
    end

    desc "revert", "Reverts the website to the previous release."
    def revert
      Revert.new.start
    end

    desc "setup", "First-time setup of the website, so it can be deployed later."
    def setup
      Setup.new.start
    end
  end
end
