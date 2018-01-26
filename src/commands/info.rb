require 'docker'
require 'colorize'
require 'json'

require_relative '../dsl/eval'
require_relative 'base'

class Info < CommandBase

    def build (options)
        file = File.expand_path(options[:fileName], Dir.getwd)
        shuttlConfig = ShuttlDSL.load file, options[:stage]
        # tar = shuttlConfig.makeImage options[:stage], @cwd
        $stdout.puts shuttlConfig.makeDockerFile options[:stage]
    end

    def run (options)
        if options[:showDocker]
            self.build options
        end
        if options[:showIP]
            if isRunning?
                $stdout.puts "IP Address: #{@info['containers'][@cwd]["json"]['NetworkSettings']['IPAddress']}".green
            else
                $stderr.puts "No container running for this dir!".red
            end
        end
        if options[:container]
            if isRunning?
                puts JSON.pretty_generate(@container.json)
            else
                $stderr.puts "No container running for this dir!".red
            end
        end
        if options[:status]
            if isRunning?
                if @container.json["State"]['Running']
                    $stdout.puts "Shuttl is up and running!".green
                else
                    @container.json["State"].each do |name, value|
                        puts "#{name}: #{value}" 
                    end
                end
            else
                $stderr.puts "No container running for this dir!".red
            end
        end
    end

end