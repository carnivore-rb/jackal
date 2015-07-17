require 'jackal'

module Jackal
  module Utils
    # Event generation helper
    module Events

      # Send event
      #
      # @param type [String, Symbol] event type
      # @param data [Smash] optional data
      # @return [NilClass]
      def event!(type, data=Smash.new)
        event_source = Carnivore::Supervisor.supervisor[:events]
        if(event_source)
          payload = new_payload(
            :event, :event => Smash.new(
              :type => type,
              :stamp => Time.now.to_f,
              :data => data
            )
          )
          debug "Sending event data - type: #{type} ID: #{payload[:id]} data: #{data.inspect}"
          event_source.transmit(payload)
        end
      end

    end
  end
end
