require 'jackal'

module Jackal
  module Utils
    module Config

      # @return [Array] key path in configuration
      def config_path(class_name = self.class.name)
        class_name.split('::')[0,2].map do |string|
          string.gsub(/(?<![A-Z])([A-Z])/, '_\1').sub(/^_/, '').downcase
        end
      end

      # @return [String] prefix of source for this callback
      def source_prefix
        config_path.join('_')
      end

      # @return [Hash] service configuration
      def service_config
        Carnivore::Config.get(*config_path) || Smash.new
      end

      # @return [Hash] configuration
      def config
        service_config[:config] || Smash.new
      end

      # Generation destination key based on direction
      #
      # @param direction [Symbol, String]
      # @return [Symbol]
      def destination(direction = :output)
        [source_prefix, direction].map(&:to_s).join('_').to_sym
      end

    end
  end
end
