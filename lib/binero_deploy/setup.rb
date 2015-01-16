module BineroDeploy
  class Setup
    def initialize
      @config = Config.parse

      @app = @config.fetch(:app)
      @console = Console.new(prompt: 'Setup')
      @remote_host = RemoteHost.new(
        host:    @config.fetch(:host),
        app:     @app,
        console: @console
      )
    end

    def start
      @console.info("Starting initial setup of #{@app.blue}")

      @remote_host.setup_app

      @console.success("Successfully setup #{@app.blue} on the remote!")
    end
  end
end
