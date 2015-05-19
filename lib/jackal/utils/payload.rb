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
        if(message[:content])
          result = message[:content].to_smash
        else
          msg = message[:message].to_smash
          result = msg.fetch(:payload, msg)
        end
        if(respond_to?(:pre_formatters) && (pre_formatters && !pre_formatters.empty?))
          pre_formatters.each do |formatter|
            begin
              formatter.format(result)
            rescue => e
              error "Formatter error encountered (<#{formatter}>): #{e.class} - #{e}"
            end
          end
        end
        result
      end

    end

  end
end
