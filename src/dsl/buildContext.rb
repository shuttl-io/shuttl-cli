class Builder 

    attr_accessor :stage, :buildStage, :buildSettings, :volumes, :entrypoint
    def initialize (fileLocation, stage=nil, name=nil)
        @name = name
        @buildStage = stage
        @buildSettings = { :settings => {}, :docker => [], :files => {}, :volumes => {} }
        @entrypoint = nil
        @volumes = {}
        @cwd = Dir.getwd
        @fileLocation = fileLocation
        @output = Tempfile.new('shuttlBuild')
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
                if File.directory? potentialFileName
                    raise Errno::EISDIR
                end
                found = File.open(potentialFileName)
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

    def addFile(localName, nameInDocker, rootName=nil)
        if rootName.nil?
            rootName = nameInDocker
        end
        begin
            file = findFile(localName)
        rescue Errno::EISDIR
            @tar.mkdir(nameInDocker, 0640)
            Dir["#{localName}/**/*"].each do |file|
                pathInDocker = File.join(rootName, file)
                addFile(file, pathInDocker, rootName)
            end
            return
        end

        permissions = file.is_a?(Hash) ? file[:permissions] : 0640
        @tar.add_file(nameInDocker, permissions) do | tarFile | 
            while buffer = file.read(1024 * 1000)
                tarFile.write(buffer)
            end
        end
        @tar.flush
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
        settings = @buildSettings[:settings]
    end

    def makeDockerFile (stage)
        settings = gatherSettings(stage)
        settingsArr = []
        settings.each do |key, value|
            settingsArr << "ARG #{key}=#{value}"
            settingsArr << "ENV #{key}=${#{key}}"
        end
        definition = @buildSettings[:docker]
        definition = [definition[0], ] + settingsArr + definition[1..definition.count]
        if @entrypoint
            definition << "ENTRYPOINT #{@entrypoint}"
        end
        volumes = gatherVolume stage
        definition << "RUN echo 'echo SHUTTL IMAGE BOOTED' >> /.shuttl/run"
        definition << "RUN echo 'bash /.shuttl/start' >> /.shuttl/run"
        if volumes.keys.count > 0
            definition << "VOLUME #{volumes.keys}"
        end
        definition.join("\n") 
    end


    def gatherFiles (stage, cwd)
        files = @buildSettings[:files]
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

    def build (stage, cwd, clean )
        begin
            makeImage stage, cwd
            query = {}
            query[:buildargs] = {}
            @buildSettings[:settings].each do |key, value|
                query[:buildargs][key] = value.to_s
            end
            query[:buildargs] = query[:buildargs].merge @env || Hash[]
            puts query[:buildargs]
            query[:buildargs] = query[:buildargs].to_json
            if clean
                query[:nocache] = true
            end
            puts query
            Docker::Image.build_from_tar @output.tap(&:rewind), query do |v|
                yield v
            end
        ensure
            @output.close
            @output.unlink
        end
    end

    def add (command)
        @buildSettings[:docker] << command
    end

    def fileAdd (source, destination)
        @buildSettings[:files][source] = destination
        add "ADD #{destination} #{destination}"
    end 

    def set (setting, value)
        @buildSettings[:settings][setting] = value
    end

    def on (name)
        if name != @buildStage
            return
        end
        yield
    end
    
    def merge (other)
        newInfo = @buildSettings.merge(other.buildSettings) do |key, old, newVal|
            if key == :settings
                old.merge newVal
            elsif key == :files
                old.merge newVal
            elsif key == :docker
                old.concat newVal
            end
        end
        @buildSettings = newInfo
        @volumes = other.volumes.merge @volumes
        
    end

    def attach(localDir, volume)
        if localDir == 'pwd'
            localDir = @cwd
        end
        @volumes[volume] = localDir
    end

    def gatherVolume(stage)
        @volumes
    end

    def setEnvFile(env)
        if env.nil?
            @env = Hash[]
            return
        end
        File.open(env, 'r') do |fi|
            @env = JSON.parse(fi.read)
        end
    end

    def cmd (cmd)
        add "CMD #{cmd}"
    end
end