require 'jackal'

module Jackal
  # Jackal customized callback
  class Callback < Carnivore::Callback

    include Utils::Payload
    include Utils::Config
    # @!parse include Jackal::Utils::Payload
    # @!parse include Jackal::Utils::Config

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
      destination = "#{source_prefix}_error"
      source = Carnivore::Supervisor.supervisor[destination]
      if(source)
        error "Sending #{message} to error handler: #{source}"
        source.transmit(payload)
      else
        error "No error source found for generated source path: #{destination}"
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
      forward(payload)
    end

    # Forward payload to output source
    #
    # @param payload [Hash]
    def forward(payload)
      destination = "#{source_prefix}_output"
      source = Carnivore::Supervisor.supervisor[destination]
      if(source)
        info "Forwarding payload to output destination... (#{source})"
        debug "Forwarded payload: #{payload.inspect}"
        source.transmit(payload)
      else
        warn "No destination source found for generated source path: #{destination}"
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

  end
end
