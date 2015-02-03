require 'jackal'

module Jackal
  # Helper utilities
  module Utils

    autoload :Spec, 'jackal/utils/spec'
    autoload :Payload, 'jackal/utils/payload'
    autoload :Config, 'jackal/utils/config'
    autoload :Constants, 'jackal/utils/constants'
    autoload :HttpApi, 'jackal/utils/http_api'
    autoload :Process, 'jackal/utils/process'

    extend Payload
    extend Constants

    class << self

      # Load the HTTP Hook if configured
      #
      # @return [TrueClass, FalseClass]
      def load_http_hook
        if(Carnivore::Config.get(:jackal, :http_hook))
          Carnivore.configure do
            Carnivore::Source.build(
              :type => :http_endpoints,
              :args => {
                :name => :jackal_http_hook,
                :bind => Carnivore::Config.fetch(:jackal, :http_hook, :bind, "0.0.0.0"),
                :port => Carnivore::Config.fetch(:jackal, :http_hook, :port, 8989)
              }
            )
          end
          true
        else
          false
        end
      end

    end

  end
end
