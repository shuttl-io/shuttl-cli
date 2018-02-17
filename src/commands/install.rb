require 'docker'
require 'json'
require 'colorize'
require 'net/http'
require 'zip'

require_relative '../dsl/eval'
require_relative 'base'

class Install < CommandBase

    def initialize
        if !File.exists? File.join(Dir.home, '.shuttl/info')
            Dir.mkdir(File.join(Dir.home, ".shuttl/info"), 0700)
        end
        super
    end

    def run (options)
        tempFile = Tempfile.new('shuttl.zip')        
        Net::HTTP.start("s3.us-east-2.amazonaws.com") do |http|
            resp = http.get("/shuttl-cli/shuttlinfo.zip")
            tempFile.write(resp.body)
        end
        tempFile.close
        Zip::File.open(tempFile.path) do |zip_file|
            # Handle entries one by one
            zip_file.each do |entry|
              # Extract to file/directory/symlink
              entry.extract(File.join(options[:installPath], entry.name.gsub('.shuttl/', ''))) {true}
            end
        end
        tempFile.unlink

        base = {
            :images => {},
            :containers => {},
        }

        File.open(File.join(Dir.home, '.shuttl/info'), 'w') do |fi|
            fi.write base.to_json
        end
    end

end