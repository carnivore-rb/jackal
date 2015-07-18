require 'jackal'

module Jackal
  # Helper utilities
  module Utils

    # Valid configuration paths for hook configuration
    HTTP_HOOK_CONFIG = [
      [:http_hook],
      [:jackal, :http_hook]
    ]

    autoload :Spec, 'jackal/utils/spec'
    autoload :Payload, 'jackal/utils/payload'
    autoload :Config, 'jackal/utils/config'
    autoload :Constants, 'jackal/utils/constants'
    autoload :HttpApi, 'jackal/utils/http_api'
    autoload :Process, 'jackal/utils/process'
    autoload :Events, 'jackal/utils/events'

    extend Payload
    extend Constants

    class << self

      # Load the HTTP Hook if configured
      #
      # @return [TrueClass, FalseClass]
      def load_http_hook
        hook_config = HTTP_HOOK_CONFIG.map do |path|
          Carnivore::Config.get(*path)
        end.compact.first
        if(hook_config)
          Carnivore.configure do
            Carnivore::Source.build(
              :type => :http_endpoints,
              :args => {
                :name => :jackal_http_hook,
                :bind => hook_config.fetch(:bind, "0.0.0.0"),
                :port => hook_config.fetch(:port, 8989)
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
