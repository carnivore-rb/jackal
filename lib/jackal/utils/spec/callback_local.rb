require 'jackal'

module Jackal
  module Utils
    module Spec
      # Callback helper module for isolated testing
      module CallbackLocal

        # @return [Array] forwarded payloads
        def forwarded
          @forwarded ||= []
        end

        # Force payload into local store
        #
        # @param payload [Hash]
        def forward(payload)
          @forwarded << payload
        end

      end
    end
  end
end
