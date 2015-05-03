require 'carnivore'
require 'bogo-config'

module Jackal
  autoload :Cli, 'jackal/cli'
  autoload :Callback, 'jackal/callback'
  autoload :Error, 'jackal/error'
  autoload :Formatter, 'jackal/formatter'
  autoload :Utils, 'jackal/utils'
  autoload :Loader, 'jackal/loader'

  class ServiceConfiguration < Bogo::Config
    attribute :description, String
    attribute :configuration, Smash, :coerce => lambda{|v| v.to_smash}
  end

  # Add service information
  #
  # @param name [String, Symbol] name of service
  # @param args [Hash] service information
  # @option args [String] :description
  # @option args [Hash] :configuration
  # @return [NilClass]
  def self.service(name, args={})
    @services[name] = ServiceConfiguration.new(args)
    nil
  end

  # @return [Smash] registered service info
  def self.service_info
    @services.to_smash
  end

  @services = Smash.new
end

require 'jackal/version'
