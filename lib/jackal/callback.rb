require 'jackal'

module Jackal
  # Jackal customized callback
  class Callback < Carnivore::Callback

    include Utils::Payload

    # @return [Array] key path in configuration
    def config_path
      self.class.name.split('::')[0,2].map do |string|
        string.gsub(/(?<![A-Z])([A-Z])/, '_\1').sub(/^_/, '').downcase
      end
    end

    # @return [String] prefix of source for this callback
    def source_prefix
      config_path.join('_')
    end

    # @return [Hash] configuration
    def config
      Carnviore::Config.get(*config_path.push(:config)) || Smash.new
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
      destination = "#{source_prefix}_error"
      source = Carnivore::Supervisor.supervisor[destination]
      error "Sending #{message} to error handler: #{source}"
      source.transmit(payload)
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
      info "Forwarding payload to output destination... (#{source})"
      debug "Forwarded payload: #{payload.inspect}"
      source.transmit(payload)
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
