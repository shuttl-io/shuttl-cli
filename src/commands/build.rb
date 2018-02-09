require 'docker'
require 'json'

require_relative '../dsl/eval'
require_relative 'base'

class Build < CommandBase

    def build (options)
        $stdout.print "Building new image\n"        
        file = File.expand_path(options[:fileName], Dir.getwd)
        shuttlConfig = ShuttlDSL.load file, options[:stage]
        # tar = shuttlConfig.makeImage options[:stage], @cwd
        begin
            step = 1
            @image = shuttlConfig.build options[:stage], @cwd, options[:clean] do |v|
                if (log = JSON.parse(v)) && log.has_key?("stream")
                    $stdout.puts log['stream']
                    if log['stream'].include? 'Step'
                        step += 1
                    end
                end
            end
            if !shuttlConfig.getName().nil?
                @image.tag('repo' => shuttlConfig.getName())
            end
            @info['images'][@cwd] = {:image_id => @image.id, :volumes => shuttlConfig.gatherVolume(options[:stage]), :built => Time.now.to_i, :stage => options[:stage]}
        rescue Docker::Error::UnexpectedResponseError => error
            $stderr.puts "Build Failed!".red
        end
    end

    def run (options)
        self.build options
    end

end