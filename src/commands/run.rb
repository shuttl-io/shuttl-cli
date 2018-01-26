require 'docker'
require 'colorize'

require_relative 'base'

class Run < CommandBase
    
    def run (options)
        if !isRunning?
            $stdout.puts "Shuttl not running! run shuttl start".red
            return
        end
        fd = IO.sysopen "/dev/tty", "w"
        ios = IO.new(fd, "w")
        output = @container.exec(@args, tty: true) do |stream| 
            ios.print stream
        end
        ios.close
    end

end