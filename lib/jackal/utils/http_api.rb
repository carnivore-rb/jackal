require 'jackal'

begin
  require 'carnivore-http'
  require 'carnivore-http/point_builder'
rescue LoadError
  $stderr.puts 'The `carnivore-http` gem must be installed and available!'
  raise
end

module Jackal
  module Utils

    # Customized point builder to provide jackal helpers
    class HttpApi < Carnivore::Http::PointBuilder; end

  end

end

class Carnivore::Http::PointBuilder::Endpoint
  include Jackal::Utils::Payload
  include Jackal::Utils::Config
  # @!parse include Jackal::Utils::Payload
  # @!parse include Jackal::Utils::Config
end
