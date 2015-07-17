$LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__)) + '/lib/'
require 'jackal/version'
Gem::Specification.new do |s|
  s.name = 'jackal'
  s.version = Jackal::VERSION.version
  s.summary = 'Message processing helper'
  s.author = 'Chris Roberts'
  s.email = 'code@chrisroberts.org'
  s.homepage = 'https://github.com/carnivore-rb/jackal'
  s.description = 'Message processing helper'
  s.require_path = 'lib'
  s.license = 'Apache 2.0'
  s.add_runtime_dependency 'carnivore', '>= 0.3.14', '< 1.0.0'
  s.add_runtime_dependency 'bogo', '>= 0.1.24', '< 1.0.0'
  s.add_runtime_dependency 'bogo-cli', '~> 0.1'
  s.add_runtime_dependency 'bogo-config', '>= 0.1.12', '< 1.0.0'
  s.add_runtime_dependency 'childprocess'
  s.add_development_dependency 'carnivore-actor'
  s.files = Dir['{lib,bin}/**/**/*'] + %w(jackal.gemspec README.md CHANGELOG.md CONTRIBUTING.md LICENSE)
  s.executables << 'jackal'
  s.executables << 'jackal-test'
end
