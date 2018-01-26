
class Loader
    # require '../dsl/eval'    
    def initialize
        @dirs = []
        shuttlDir = File.join(Dir.home, '.shuttl/definitions')
        @dirs << shuttlDir
        if ENV.key('SHUTTL_PATH')
            @dirs << ENV['SHUTTL_PATH'].split(":")
        end
        @dirs << Dir.getwd
    end

    def find (name)
        found = nil
        [name, "#{name}.shuttlfile"].each do |fileName|
            found = findFile(fileName)
            if !found.nil?
                break
            end
        end
        if found.nil?
            throw "No shuttl file found"
        end
        found
    end

    def findFile (file)
        found = nil
        @dirs.each do | dir |
            potentialFileName = File.join(dir, file)
            if File.exist? potentialFileName
                found = ShuttlDSL.load potentialFileName
                break
            end
        end
        found
    end
end