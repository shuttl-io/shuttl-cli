require 'json'

Dir.mkdir File.join(Dir.home, '.shuttl')
Dir.mkdir File.join(Dir.home, '.shuttl/definitions')

base = {
    :images => {},
    :containers => {},
}

File.open(File.join(Dir.home, '.shuttl/info'), 'w') do |fi|
    fi.write base.to_json
end