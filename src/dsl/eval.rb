require_relative 'Shuttl'
require_relative 'buildContext'

class ShuttlDSL
  
    def self.load(filename, stage)
      builder = Builder.new File.dirname(filename), stage
      dsl = Shuttl.new builder
      dsl.instance_eval(File.read(filename), filename)
      return builder
    end

end

