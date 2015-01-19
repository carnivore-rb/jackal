require 'jackal'

module Jackal
  # Payload formatter
  class Formatter

    class << self

      # Register formatter
      def inherited(klass)
        Formatter.descendants.push(klass).uniq!
      end

      # @return [Array<Class>] registered formatters
      def descendants
        @_descendants ||= []
      end

    end

    # @return [String, Symbol]
    SOURCE = nil
    # @return [String, Symbol]
    DESTINATION = nil

    # Create a new instance
    #
    # @return [self]
    def initialize(callback=nil)
      @callback = callback
      [:SOURCE, :DESTINATION].each do |key|
        unless(self.class.const_get(key))
          raise NotImplementedError.new("Formatter class must define #{key} constant")
        end
      end
    end

    # Provide a simple proxy out to originating callback if provided
    # to access helpers
    def method_missing(m_name, *args, &block)
      if(@callback && @callback.respond_to?(m_name))
        @callback.send(m_name, *args, &block)
      else
        super
      end
    end

    # @return [Symbol]
    def source
      self.class.const_get(:SOURCE).to_sym
    end

    # @return [Symbol]
    def destination
      self.class.const_get(:DESTINATION).to_sym
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
