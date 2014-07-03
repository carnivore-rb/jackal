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

        class << self
          # Init data store for internal message capture
          def extended(klass)
            klass.instance_eval do
              @forwarded = []
            end
          end
          alias_method :included, :extended
        end

      end
    end
  end
end
