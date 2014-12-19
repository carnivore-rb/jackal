require 'jackal'

module Jackal
  # Payload formatter
  class Formatter

    # @return [String, Symbol]
    SOURCE = nil
    # @return [String, Symbol]
    DESTINATION = nil

    # Create a new instance
    #
    # @return [self]
    def initialize
      [:SOURCE, :DESTINATION].each do |key|
        unless(self.class.const_get(key))
          raise NotImplementedError.new("Formatter class must define #{key} constant")
        end
      end
    end

    # Apply format to payload
    #
    # @param payload [Smash]
    # @return payload [Smash]
    def format(payload)
      raise NotImplementedError
    end

  end
end
