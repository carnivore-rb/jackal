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

# Define default source for API if configuration exists
if(Carnivore::Config.get(:http_hook))
  Carnivore.configure do
    Carnivore::Source.build(
      :type => :http_endpoints,
      :args => {
        :name => :http_hook,
        :bind => Carnivore::Config.get(:http_hook, :bind) || "0.0.0.0",
        :port => Carnivore::Config.get(:http_hook, :port) || 8989
      }
    )
  end
end
