$LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__)) + '/lib/'
require 'carnivore-runner/version'
Gem::Specification.new do |s|
  s.name = 'carnivore-runner'
  s.version = CarnivoreRunner::VERSION.version
  s.summary = 'Message processing helper'
  s.author = 'Chris Roberts'
  s.email = 'chrisroberts.code@gmail.com'
  s.homepage = 'https://github.com/carnivore-rb/carnivore-runner'
  s.description = 'Message processing helper'
  s.require_path = 'lib'
  s.add_dependency 'carnivore'
  s.add_dependency 'mixlib-cli'
  s.files = Dir['lib/**/*'] + %w(carnivore-runner.gemspec README.md CHANGELOG.md)
  s.executables << 'carnivore-runner'
end
