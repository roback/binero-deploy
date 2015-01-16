module BineroDeploy
  class Backup
    def initialize
      @config = Config.parse
      @backup_config = @config.fetch(:backup, {})

      @app = @config.fetch(:app)
      @console = Console.new(prompt: 'Backup')
      @remote_host = RemoteHost.new(
        host:    @config.fetch(:host),
        app:     @app,
        console: @console
      )
    end

    def start
      @console.info("Starting backup of #{@app.blue}")

      db_enabled = @backup_config.fetch(:db)
      local_dir = @backup_config.fetch(:local_dir)
      @remote_host.backup_app(
        db_enabled:      db_enabled,
        local_dir:       local_dir,
      )

      @console.success("Backup done!")
    end
  end
end
