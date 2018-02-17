require 'rake';
require_relative './src/settings';

Gem::Specification.new do |s|
    s.name        = 'shuttl'
    s.version     = ShuttlSettings::VERSION
    s.date        = '2010-04-28'
    s.summary     = "Shuttl!"
    s.description = "Shuttl builds doccker images easily"
    s.authors     = ["Yoseph Radding"]
    s.email       = 'yoseph@shuttl.io'
    s.files       = FileList["bin/shuttl", 'src/**/*'].to_a
    s.homepage    = 'https://github.com/shuttl-io/shuttl-cli'
      'http://rubygems.org/gems/shuttl'
    s.license       = 'MIT'
    s.post_install_message = "Thanks for installing! Run shuttl install to complete the install"
    s.executables   = ["shuttl"]
    s.require_paths = ["src"]
    s.add_runtime_dependency 'docker-api', '~> 1.34.0', '>= 1.34.0'
    s.add_runtime_dependency 'colorize', '~> 0.8.1'
    s.add_runtime_dependency 'rubyzip', '~> 1.2.0', '>= 1.2.0'
  end
