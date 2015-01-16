require 'colorize'

module BineroDeploy
  class Console
    def initialize(prompt: '')
      @prompt = prompt
    end

    def err(message)
      type = 'error'.red
      output(type, message)
    end

    def success(message)
      type = 'success'.green
      output(type, message)
    end

    def info(message)
      type = 'info'.light_blue
      output(type, message)
    end

    private
    def output(type, message)
      puts "[#{@prompt.green}][#{type}] #{message}"
    end
  end
end
