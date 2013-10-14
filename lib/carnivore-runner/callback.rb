require 'carnivore/callback'

module CarnivoreRunner
  class Callback < Carnivore::Callback

    def forward(destination, payload)
      Celluloid::Actor[destination].transmit(payload)
    end

  end
end
