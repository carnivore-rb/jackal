require 'carnivore/callback'

module Jackal
  class Callback < Carnivore::Callback

    def new_payload(payload)
      {
        :id => Celluloid.uuid,
        :data => payload
      }
    end

    def forward(destination, payload)
      Celluloid::Actor[destination].transmit(payload)
    end

  end
end
