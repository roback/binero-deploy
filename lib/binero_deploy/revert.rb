module BineroDeploy
  class Revert
    def initialize
      @config = Config.parse

      @app = @config.fetch(:app)
      @console = Console.new(prompt: 'Revert')
      @remote_host = RemoteHost.new(
        host:    @config.fetch(:host),
        app:     @app,
        console: @console
      )
    end

    def start
      @console.info("Starting revert of #{@app.blue}")

      @remote_host.revert_app_to_previous_release

      @console.success("Successfully reverted to the previous release!")
    end
  end
end
