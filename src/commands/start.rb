require 'docker'
require 'colorize'

require_relative '../dsl/eval'
require_relative 'base'

class Booted < StandardError
end

class Start < CommandBase
    
    def build (options)
        $stdout.print "Building new image\n"        
        file = File.expand_path(options[:fileName], Dir.getwd)
        shuttlConfig = ShuttlDSL.load file, options[:stage]
        begin
            step = 1
            @image = shuttlConfig.build options[:stage], @cwd do |v|
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
            @info['images'][@cwd] = {:image_id => @image.id, :volumes => shuttlConfig.gatherVolume(options[:stage]), :built => Time.now.to_i}
        rescue Docker::Error::UnexpectedResponseError => error
            $stderr.puts error
        end
    end
    
    def startContainer (options)
        $stdout.puts "Starting image"
        @container = Docker::Container.create(
            'Image' => @image.id,
            'HostConfig' => {
                "Binds" => @current_image_info['volumes'].map {|mountPoint, hostDir| "#{hostDir}:#{mountPoint}"}
            }
        ).start
        begin
            catch (Booted) do 
                @container.tap(&:start).attach do |stream, chunk| 
                    if chunk.include? 'SHUTTL IMAGE BOOTED'
                        throw Booted
                    end
                    $stdout.puts "#{stream}: #{chunk}" 
                end
            end
            $stdout.puts "Container is fully booted and ready for use!".green
            $stdout.puts "Container's id is #{@container.id} and the IP is: #{@container.json['NetworkSettings']['IPAddress']}".green      
        rescue Exception => e
            $std.puts  "error: #{e}"
        end
        @info['containers'][@cwd] = {:container_id => @container.id, :status => 'running', :json => @container.json }
    end

    def shouldRebuild?(mtime)
        @current_image_info["built"] < mtime.to_i
    end


    def run (options)
        if self.isRunning?
            $stdout.puts "Already running!"
            return
        end
        if self.hasImage? && !shouldRebuild?(File.mtime(File.expand_path(options[:fileName], Dir.getwd)))
            return self.startContainer options
        end
        self.build options
        self.startContainer options
    end

end