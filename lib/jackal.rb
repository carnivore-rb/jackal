require 'carnivore'
require 'bogo-config'

module Jackal
  autoload :Cli, 'jackal/cli'
  autoload :Callback, 'jackal/callback'
  autoload :Error, 'jackal/error'
  autoload :Formatter, 'jackal/formatter'
  autoload :Utils, 'jackal/utils'
  autoload :Loader, 'jackal/loader'

  class ServiceInformation < Bogo::Config
    class Configuration < Bogo::Config
      attribute :name, Symbol, :required => true, :coerce => lambda{|v| v.to_sym}
      attribute :type, Symbol, :required => true, :default => :string, :allowed_values => [:string, :hash, :number]
      attribute :description, String
      attribute :public, [TrueClass, FalseClass], :default => true, :required => true
    end

    attribute :name, Symbol, :required => true, :coerce => lambda{|v| v.to_sym}
    attribute :configuration, Configuration, :coerce => lambda{|v| Configuration.new(v.map{|name,hsh| hsh.merge(:name => name)})}
  end


  # Add service information
  #
  # @param name [String, Symbol] name of service
  # @param args [Hash] service information
  # @option args [String] :description
  # @option args [Hash] :configuration
  # @return [NilClass]
  def self.service(name, args={})
    @services[name] = ServiceInformation.new(args)
    nil
  end

  # @return [Smash] registered service info
  def self.service_info
    @services.to_smash
  end

  @services = Smash.new
end

require 'jackal/version'
