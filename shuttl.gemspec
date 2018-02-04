require 'rake';

Gem::Specification.new do |s|
    s.name        = 'shuttl'
    s.version     = '1.1.0'
    s.date        = '2010-04-28'
    s.summary     = "Shuttl!"
    s.description = "Shuttl builds doccker images easily"
    s.authors     = ["Yoseph Radding"]
    s.email       = 'yoseph@shuttl.io'
    s.files       = FileList["bin/shuttl", 'src/**/*'].to_a
    s.homepage    =
      'http://rubygems.org/gems/shuttl'
    s.license       = 'MIT'
    s.post_install_message = "Thanks for installing! Run shuttl install to complete the install"
    s.executables   = ["shuttl"]
    s.require_paths = ["src"]
  end