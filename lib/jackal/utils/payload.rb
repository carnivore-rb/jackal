require 'jackal'

module Jackal
  module Utils

    # Payload helper utilities
    module Payload

      # Generate a new payload
      #
      # @param name [String]
      # @param payload [Hash]
      # @param args [Object] extra arguments
      # @return [Smash]
      def new_payload(name, payload, *args)
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
        msg = message[:message].to_smash
        msg.fetch(:payload, msg)
      end

    end

  end
end
