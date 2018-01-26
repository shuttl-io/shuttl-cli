class Builder 

    attr_accessor :stage
    def initialize (fileLocation, name=nil)
        @name = name
        @stage = Hash[:complete => { :settings => {}, :docker => [], :files => {}, :volumes => {} }]
        @current_stage = :complete
        @entrypoint = nil
        @volumes = {}
        @cwd = Dir.getwd
        @fileLocation = fileLocation
        @output = StringIO.new
        @tar = Gem::Package::TarWriter.new(@output)
        @dirs = [fileLocation, Dir.getwd, File.join(Dir.home, '.shuttl/definitions')]
        if ENV.key('SHUTTL_PATH')
            @dirs << ENV['SHUTTL_PATH'].split(":")
        end
    end

    def findFile(name)
        found = nil
        @dirs.each do | dir |
            potentialFileName = File.join(dir, name)
            if File.exist? potentialFileName
                found = File.read(potentialFileName)
                break
            end
        end
        if found.nil?
            throw "File not found: #{name}"
        end
        found
    end

    def setName(name)
        @name = name
    end

    def getName        
        @name
    end

    def addFile(localName, nameInDocker)
        file = findFile(localName)
        permissions = file.is_a?(Hash) ? file[:permissions] : 0640
        @tar.add_file(nameInDocker, permissions) do | tarFile | 
            content = file.is_a?(Hash) ? file[:content] : file
            tarFile.write(content)
        end
    end

    def create_tar(hash = {}, tap=true)
        output = StringIO.new
        Gem::Package::TarWriter.new(output) do |tar|
            hash.each do |file_name, file_details|
                permissions = file_details.is_a?(Hash) ? file_details[:permissions] : 0640
                tar.add_file(file_name, permissions) do |tar_file|
                    content = file_details.is_a?(Hash) ? file_details[:content] : file_details
                    tar_file.write(content)
                end
            end
        end
        return output.tap(&:rewind)
    end

    def gatherSettings (stage)
        settings = @stage[:complete][:settings]
        if !@stage[stage].nil?
            settings = settings.merge @stage[stage][:settings]
        end
        settings
    end

    def makeDockerFile (stage)
        settings = gatherSettings(stage)
        settingsArr = []
        settings.each do |key, value|
            settingsArr << "ARG #{key}=#{value}"
            settingsArr << "ENV #{key}=${#{key}}"
        end
        definition = @stage[:complete][:docker]
        stageDef = @stage[stage]
        if !stageDef.nil?
            definition = definition.concat stageDef[:docker]
        end
        definition = [definition[0], ] + settingsArr + definition[1..definition.count]
        if @entrypoint
            definition << "ENTRYPOINT #{@entrypoint}"
        end
        volumes = gatherVolume stage
        definition << "RUN echo 'echo SHUTTL IMAGE BOOTED' >> /.shuttl/run"
        definition << "RUN echo 'bash /.shuttl/start' >> /.shuttl/run"
        definition << "VOLUME #{volumes.keys}"
        definition.join("\n") 
    end


    def gatherFiles (stage, cwd)
        files = @stage[:complete][:files]
        stageDef = @stage[stage]
        if !stageDef.nil?
            files = files.merge stageDef[:files]
        end
        files
    end

    def makeImage (stage, cwd)
        dockerfile = self.makeDockerFile stage
        files = self.gatherFiles stage, cwd
        @tar.add_file("Dockerfile", 0640) do |tar_file|
            tar_file.write(dockerfile)
        end
        files.each do |key, val|
            addFile(key, val)
        end
    end

    def build (stage, cwd, block=nil )
        makeImage stage, cwd
        query = @stage[:complete][:settings]
        if !@stage[stage].nil?
            query = query.merge @stage[stage][:settings] 
        end
        Docker::Image.build_from_tar @output.tap(&:rewind), :query => query do |v|
            yield v
        end
    end

    def add (command)
        @stage[@current_stage][:docker] << command
    end

    def fileAdd (source, destination)
        @stage[@current_stage][:files][source] = destination
        add "ADD #{destination} #{destination}"
    end 

    def set (setting, value)
        @stage[@current_stage][:settings][setting] = value
    end

    def on (name)
        if !@stage.key?(name)
            @stage[name] = Hash[:settings => {}, :docker => [], :files => {}, :volumes => {}]
        end
        @current_stage = name
        yield
        @current_stage = :complete
    end
    
    def merge (other)
        newInfo = @stage.merge(other.stage) do |key, old, newVal|      
            newVal.merge old do |key, old, newVal|
                if key == :settings
                    old.merge newVal
                elsif key == :files
                    old.merge newVal
                elsif key == :docker
                    old.concat newVal
                end
            end
        end
        @stage = newInfo
        # @stage = @stage.merge(other.stage)
    end

    def attach(localDir, volume)
        if localDir == 'pwd'
            localDir = @cwd
        end
        @stage[@current_stage][:volumes][volume] = localDir
    end

    def gatherVolume(stage)
        volumes = @stage[:complete][:volumes] || Hash[]
        if !@stage[stage].nil?
            volumes = volumes.merge @stage[stage][:volumes]
        end
        volumes
    end

end