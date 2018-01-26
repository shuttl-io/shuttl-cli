require 'docker'
require 'colorize'

require_relative 'base'

class SSH < CommandBase
    
    def run (options)
        if !isRunning?
            $stderr.puts "Shuttl not running! run shuttl start".red
            return
        end
        fd = IO.sysopen "/dev/tty", "w"
        ios = IO.new(fd, "w")
        ios.raw!
        begin
            @container.exec(['/bin/bash'], stdin: $stdin, tty: true, stdout: true, stderr: true, stream: true) do |stream|
                ios.print stream
            end
        rescue Interrupt => e
        rescue Exception => e
            $stderr.puts "Error: #{e}".red
        end
        ios.close
        ## The space is put before the command so that it won't show up in bash history
        ` stty sane`
    end

end