require 'jackal'

module Jackal
  module Utils

    autoload :Spec, 'jackal/utils/spec'

    module Payload

      def new_payload(payload)
        Smash.new(
          :id => Celluloid.uuid,
          :data => payload
        )
      end

    end

    extend Payload

  end
end
