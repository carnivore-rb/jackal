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
      attribute :type, Symbol, :required => true, :default => :string, :allowed_values => [:string, :hash, :array, :number, :boolean]
      attribute :description, String
      attribute :public, [TrueClass, FalseClass], :default => true, :required => true
    end

    attribute :name, Symbol, :required => true, :coerce => lambda{|v| v.to_sym}
    attribute :description, String
    attribute :category, Symbol, :allowed_values => [:full, :modifier, :notifier], :default => :full, :multiple => true
    attribute :configuration, Configuration, :multiple => true, :default => [], :coerce => lambda{|v|
      Smash.new(
        :bogo_multiple => v.map{|name, hsh|
          Configuration.new(hsh.merge(:name => name))
        }
      )
    }
  end

  # Add service information
  #
  # @param name [String, Symbol] name of service
  # @param args [Hash] service information
  # @option args [String] :description
  # @option args [Hash] :configuration
  # @return [NilClass]
  def self.service(name, args={})
    name = name.to_s
    if(@services[name])
      new_config = ServiceInformation.new(args.merge(:name => name))
      @services[name] = ServiceInformation.new(
        @services[name].data.merge(
          :configuration => (
            @services[name].data[:configuration] |
            new_config.data[:configuration]
          )
        )
      )
    else
      @services[name] = ServiceInformation.new(args.merge(:name => name))
    end
    nil
  end

  # @return [Smash] registered service info
  def self.service_info
    @services.to_smash
  end

  @services = Smash.new
end

require 'jackal/version'
