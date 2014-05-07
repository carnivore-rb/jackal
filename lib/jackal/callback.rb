require 'jackal'

module Jackal
  class Callback < Carnivore::Callback

    def config_path
      self.class.name.split('::')[0,2].map do |string|
        string.gsub(/(?<![A-Z])([A-Z])/, '_\1').sub(/^_/, '').downcase
      end
    end

    def source_prefix
      config_path.join('_')
    end

    def config
      Carnviore::Config.get(*config_path)
    end

    def new_payload(payload)
      Smash.new(
        :id => Celluloid.uuid,
        :data => payload
      )
    end

    # message:: Original message
    # Executes block and catches unexpected exceptions if encountered
    def failure_wrap(message)
      abort 'Failure wrap requires block for execution' unless block_given?
      begin
        payload = message[:message]
        yield payload
      rescue => e
        error "!!! Unexpected failure encountered -> #{e.class}: #{e}"
        debug "#{e.class}: #{e}\n#{(e.backtrace || []).join("\n")}"
        failed(payload, message, e.message)
      end
    end

    def failed(payload, message, reason='No reason provided')
      error "Processing of #{message} failed! Reason: #{reason}"
      message.confirm!
      destination = "#{source_prefix}_error"
      source = Carnivore::Supervisor.supervisor[destination]
      error "Sending #{message} to error handler: #{source}"
      source.transmit(payload)
    end

    def completed(payload, message)
      message.confirm!
      info "Processing of #{message} complete on this callback"
      forward(payload)
    end

    def forward(payload)
      destination = "#{source_prefix}_output"
      source = Carnivore::Supervisor.supervisor[destination]
      info "Forwarding payload to output destination... (#{source})"
      debug "Forwarded payload: #{payload.inspect}"
      source.transmit(payload)
    end

    def job_completed(name, payload, message)
      info "Processing of message #{message} has completed within this component #{name}"
      message.confirm!
      forward(payload)
    end

  end
end
