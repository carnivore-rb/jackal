require 'carnivore'

module Jackal
  autoload :Cli, 'jackal/cli'
  autoload :Callback, 'jackal/callback'
  autoload :Error, 'jackal/error'
  autoload :Formatter, 'jackal/formatter'
  autoload :Utils, 'jackal/utils'
  autoload :Loader, 'jackal/loader'

  # Add service information
  #
  # @param name [String, Symbol] name of service
  # @param args [Hash] service information
  # @option args [String] :description
  # @option args [Hash] :configuration
  # @return [NilClass]
  def self.service(name, args={})
    @services[name] = args
    nil
  end

  # @return [Smash] registered service info
  def self.service_info
    @services.to_smash
  end

  @services = Smash.new
end

require 'jackal/version'
