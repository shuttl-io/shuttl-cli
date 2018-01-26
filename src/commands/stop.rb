require 'docker'

require_relative '../dsl/eval'
require_relative 'base'

class Stop < CommandBase
    
    def run (options)
        if self.isRunning?
            $stdout.puts "Stopping Shuttl instance"
            @container.kill
        else
            $stdout.puts "Not running?"
        end
            
    end

end