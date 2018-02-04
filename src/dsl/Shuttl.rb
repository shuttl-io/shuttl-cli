## Base class for the DSL definition
require 'uri'
require 'docker'

class Shuttl

    attr_accessor :name, :stage

    def initialize (builder)
        @builder = builder
    end

    def DEFINES (name)
        @builder.setName(name)
    end

    def add (command)
        @builder.add command
    end

    def fileAdd (source)
        @builder.fileAdd source
    end 

    def FROM (name)
        self.add "FROM #{name}"
    end

    def RUN (name)
        self.add "RUN #{name}"
    end

    def ADD (source, destination)
        if source !=~ /\A#{URI::regexp}\z/
            @builder.fileAdd(source, destination)
        else
            self.add "ADD #{source} #{destination}"
        end
    end

    def COPY(source, destination)
        self.add "COPY #{source} #{destination}"
    end

    def EXPOSE (port)
        self.add "EXPOSE #{port}"
    end

    def ENTRYPOINT (entrypoint)
        @builder.entrypoint = entrypoint
    end

    def ONSTART (cmd)
        self.add "RUN echo \"#{cmd}\" >> /.shuttl/run" 
    end

    def ONRUN (cmd)
        self.add "RUN echo \"#{cmd}\" >> /.shuttl/start"
    end

    def EXTENDS (name)
        require_relative '../Shuttl/Loader'
        loader = Loader.new
        @builder.merge loader.find name, @builder.buildStage
    end

    def USE (name)
        EXTENDS name
    end

    def SET (setting, value)
        @builder.set setting, value
    end

    def ON (name)
        @builder.on name do
            yield
        end
    end

    def VOLUME (volume)
        self.add "VOLUME #{volume}"
    end

    def ATTACH (localDir, volume)
        @builder.attach(localDir, volume)
    end

    def ENVIRONMENT (tester)
        tester.call(@builder.buildSettings[:settings]['ENVIRONMENT'])
    end

    def IS (name)
        proc {|value| value == name }
    end
end