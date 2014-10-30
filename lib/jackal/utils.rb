require 'jackal'

module Jackal
  # Helper utilities
  module Utils

    autoload :Spec, 'jackal/utils/spec'
    autoload :Payload, 'jackal/utils/payload'
    autoload :Config, 'jackal/utils/config'
    autoload :HttpApi, 'jackal/utils/http_api'

    extend Payload

    class << self

      # Load thee HTTP Hook if configured
      #
      # @return [TrueClass, FalseClass]
      def load_http_hook
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
          true
        else
          false
        end
      end

    end

  end
end
