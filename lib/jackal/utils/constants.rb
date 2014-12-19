require 'jackal'

module Jackal
  module Utils
    module Constants

      # Provide constant defined by string
      #
      # @param string [String] constant to locate
      # @return [Class]
      def constantize(string)
        klass = string.to_s.split('::').inject(Object) do |memo, name|
          memo.const_get(name)
        end
      end

    end
  end
end
