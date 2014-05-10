require 'jackal'

module Jackal
  # Helper utilities
  module Utils

    autoload :Spec, 'jackal/utils/spec'

    # Module utilities
    module Payload


      # Generate a new payload
      #
      # @param name [String]
      # @param payload [Hash]
      # @return [Smash]
      def new_payload(name, payload)
        Smash.new(
          :name => name,
          :id => Celluloid.uuid,
          :data => payload
        )
      end

      # Extract payload from message
      #
      # @param message [Carnivore::Message]
      # @return [Smash]
      def unpack(message)
        Smash.new(message[:message])
      end

    end

    extend Payload

  end
end
