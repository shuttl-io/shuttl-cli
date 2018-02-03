require 'json'

class CommandBase
    def initialize
        @fileLocation = File.join(Dir.home, '.shuttl')
        File.open(File.join(@fileLocation, 'info'), 'r') do |fi|
            @info = JSON.parse(fi.read)
        end
        @cwd = Dir.getwd
    end

    def handle (options, args)
        @args = args
        self.run options
        self.cleanUp options
    end

    def run (options)
    end

    def cleanUp (options)
        File.open(File.join(Dir.home, '.shuttl/info'), 'w') do |fi|
            fi.write @info.to_json
        end
    end

    def hasImage?
        hasImage = @info['images'].key?(@cwd)
        if hasImage
            @current_image_info = @info['images'][@cwd]            
            @image = Docker::Image.get(@info['images'][@cwd]["image_id"])
        end
        hasImage
    end

    def isRunning?
        if (@info['containers'].key?(@cwd))
            begin
                @container = Docker::Container.get(@info['containers'][@cwd]["container_id"])
            rescue Docker::Error::NotFoundError
                @info['containers'].delete(@cwd)
                return false
            end
            return @container.json['State']['Running']
        end
        false
    end
end