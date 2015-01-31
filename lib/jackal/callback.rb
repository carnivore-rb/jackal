require 'jackal'

module Jackal
  # Jackal customized callback
  class Callback < Carnivore::Callback

    include Utils::Payload
    include Utils::Config
    # @!parse include Jackal::Utils::Payload
    # @!parse include Jackal::Utils::Config

    include Bogo::Constants
    include Bogo::Memoization

    # @return [Array<Formatter>] formatters
    attr_reader :formatters

    # Create new instance
    #
    # @return [self]
    def initialize(*_)
      super
      if(service_config[:formatters])
        @formatters = service_config[:formatters].map do |klass_name|
          constantize(klass_name).new
        end
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
        Utils::Process.new
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
      begin
        payload = unpack(message)
        yield payload
      rescue => e
        error "!!! Unexpected failure encountered -> #{e.class}: #{e}"
        debug "#{e.class}: #{e}\n#{(e.backtrace || []).join("\n")}"
        failed(payload, message, e.message)
      end
    end

    # Send payload to error handler
    #
    # @param payload [Hash]
    # @param message [Carnivore::Message]
    # @param reason [String]
    def failed(payload, message, reason='No reason provided')
      error "Processing of #{message} failed! Reason: #{reason}"
      message.confirm!
      dest = destination(:error, payload)
      source = Carnivore::Supervisor.supervisor[dest]
      if(source)
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
        info "Forwarding payload to output destination... (#{source})"
        debug "Forwarded payload: #{payload.inspect}"
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
      if(formatters)
        apply_formatters!(payload)
      end
      message.confirm!
      forward(payload)
    end

    # Apply configured formatters to payload
    #
    # @param payload [Smash]
    # @return [Smash]
    def apply_formatters!(payload)
      formatters.each do |formatter|
        formatter.format(payload)
      end
    end

  end
end
