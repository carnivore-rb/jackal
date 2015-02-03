require 'jackal'

module Jackal
  module Utils
    module Config

      # Load extra modules automatically
      def self.included(klass)
        klass.class_eval do
          include Bogo::AnimalStrings
        end
      end

      # Load extra modules automatically
      def self.extended(klass)
        klass.class_eval do
          extend Bogo::AnimalStrings
        end
      end

      # @return [Symbol] name of service
      def service_name(class_name = self.class.name)
        config_path(class_name).last.to_sym
      end

      # @return [Array] key path in configuration
      def config_path(class_name = self.class.name)
        class_name.split('::')[0,2].map do |string|
          snake(string)
        end
      end

      # @return [String] prefix of source for this callback
      def source_prefix
        config_path.join('_')
      end

      # @return [Smash] application configuration
      def app_config
        Carnivore::Config.fetch(
          snake(
            self.class.name.split('::').first
          ),
          Smash.new
        )
      end

      # @return [Smash] service configuration
      def service_config
        Carnivore::Config.get(*config_path) || Smash.new
      end

      # @return [Smash] configuration
      def config
        service_config[:config] || Smash.new
      end

      # Generate destination key based on direction
      #
      # @param direction [Symbol, String]
      # @param payload [Smash]
      # @return [Symbol]
      def destination(direction, payload)
        [source_prefix, direction].map(&:to_s).join('_').to_sym
      end

    end
  end
end
