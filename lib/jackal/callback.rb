require 'jackal'
require 'pp'

module Jackal
  # Jackal customized callback
  class Callback < Carnivore::Callback

    include Utils::Payload
    include Utils::Config
    include Utils::Events
    # @!parse include Jackal::Utils::Payload
    # @!parse include Jackal::Utils::Config
    # @!parse include Jackal::Utils::Events

    include Bogo::Constants
    include Bogo::Memoization

    # @return [Array<Formatter>] formatters applied on complete
    attr_reader :formatters
    # @return [Array<Formatter>] formatters applied prior
    attr_reader :pre_formatters

    # Create new instance
    #
    # @return [self]
    def initialize(*_)
      super
      if(service_config[:formatters])
        setup_formatters
      end
    end

    # Initialize any required formatters
    #
    # @return [TrueClass, FalseClass]
    def setup_formatters
      f_config = service_config[:formatters]
      case f_config
      when Hash
        @formatters = f_config.fetch(:pre, []).map do |klass_name|
          constantize(klass_name).new(self)
        end
        @pre_formatters = f_config.fetch(:post, []).map do |klass_name|
          constantize(klass_name).new(self)
        end
      when Array
        @formatters = f_config.map do |klass_name|
          constantize(klass_name).new(self)
        end
        @pre_formatters = []
      else
        error "Formatters configuration error. Unable to process type `#{f_config.class}`."
        false
      end
    end

    # @return [Jackal::Assets::Store]
    # @note the assets library is NOT a dependency of jackal and must
    #   be included at runtime!
    def asset_store
      memoize(:asset_store) do
        require 'jackal-assets'
        Jackal::Assets::Store.new
      end
    end

    # @return [Utils::Process]
    def process_manager
      memoize(:process_manager) do
        Utils::Process.new(app_config.fetch(:process_manager, Smash.new))
      end
    end

    # Validity of message
    #
    # @param message [Carnivore::Message]
    # @return [TrueClass, FalseClass]
    def valid?(message)
      m = unpack(message)
      block_given? ? yield(m) : true
    end

    # Executes block and catches unexpected exceptions if encountered
    #
    # @param message [Carnivore::Message]
    # @return [Object]
    def failure_wrap(message)
      abort 'Failure wrap requires block for execution' unless block_given?
      if(app_config[:failure_wrap] == false || service_config[:failure_wrap] == false)
        debug "Processing message with failure wrap disabled <#{message}>"
        payload = unpack(message)
        yield payload
      else
        debug "Processing message with failure wrap enabled <#{message}>"
        begin
          payload = unpack(message)
          yield payload
        rescue => e
          error "!!! Unexpected failure encountered -> #{e.class}: #{e}"
          debug "#{e.class}: #{e}\n#{(e.backtrace || []).join("\n")}"
          payload.set(:error, "#{e.class}: #{e.message}")
          failed(payload, message, e.message)
        end
      end
    end

    # Send payload to error handler
    #
    # @param payload [Hash]
    # @param message [Carnivore::Message]
    # @param reason [String]
    def failed(payload, message, reason='No reason provided')
      error "Processing of #{message} failed! Reason: #{reason}"
      unless(payload[:error])
        payload.set(:error, reason)
      end
      message.confirm!
      dest = destination(:error, payload)
      source = Carnivore::Supervisor.supervisor[dest]
      if(source)
        if(formatters)
          apply_formatters!(payload)
        end
        error "Sending #{message} to error handler: #{source}"
        source.transmit(payload)
      else
        error "No error source found for generated source path: #{dest}"
        info "Processing of message #{message} has completed. Message now discarded."
      end
    end

    # Mark payload complete and forward
    #
    # @param payload [Hash]
    # @param message [Carnivore::Message]
    def completed(payload, message)
      message.confirm!
      info "Processing of #{message} complete on this callback"
      forward(payload, source.name)
    end

    # Forward payload to output source
    #
    # @param payload [Hash]
    def forward(payload, dest=nil)
      unless(dest)
        dest = destination(:output, payload)
      end
      source = Carnivore::Supervisor.supervisor[dest]
      if(source)
        if(formatters)
          apply_formatters!(payload)
        end
        info "Forwarding payload to output destination... (#{source})"
        debug "Forwarded payload: #{payload.pretty_inspect}"
        source.transmit(payload)
      else
        warn "No destination source found for generated source path: #{dest}"
        info "Processing of message has completed. Message now discarded."
      end
    end

    # Mark job as completed
    #
    # @param name [String]
    # @param payload [Hash]
    # @param message [Carnivore::Message]
    def job_completed(name, payload, message)
      info "Processing of message #{message} has completed within this component #{name}"
      message.confirm!
      forward(payload)
    end

    # Apply configured formatters to payload
    #
    # @param payload [Smash]
    # @return [Smash]
    def apply_formatters!(payload)
      formatters.each do |formatter|
        begin
          formatter.format(payload)
        rescue => e
          error "Formatter error encountered (<#{formatter}>): #{e.class} - #{e}"
        end
      end
    end

  end
end
