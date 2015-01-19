require 'carnivore'
require 'jackal'

module Jackal
  class Loader
    class << self

      # Run the jackal
      #
      # @param opts [Hash]
      def run!(opts)

        if(ENV['JACKAL_TESTING_MODE'] && !opts[:config])
          Carnivore.configure!(:verify)
        else
          Carnivore.configure!(opts[:config])
          Carnivore::Config.immutable!
        end

        Celluloid.logger.level = Celluloid.logger.class.const_get(
          (opts[:verbosity] || Carnivore::Config[:verbosity] || :debug).to_s.upcase
        )

        Carnivore::Config.fetch(:jackal, :require, []).each do |path|
          require path
        end

        begin
          Carnivore::Config.to_smash.each do |namespace, args|
            next unless args.is_a?(Hash)
            args.each do |key, opts|
              next unless opts.is_a?(Hash) && opts[:sources]
              Carnivore::Utils.debug "Processing: #{opts.inspect}"
              Carnivore.configure do
                opts.fetch(:sources, {}).each do |kind, source_args|
                  source = Carnivore::Source.build(
                    :type => source_args[:type].to_sym,
                    :args => source_args.fetch(:args, {}).merge(:name => "#{namespace}_#{key}_#{kind}"),
                    :orphan_callback => lambda{|message|
                      warn "No callbacks matched message. Auto confirming message from source. (#{message})"
                      message.confirm!
                      if(name.to_s.end_with?('input'))
                        destination = Carnivore::Supervisor.supervisor[name.to_s.sub('_input', '_output')]
                        if(destination)
                          warn "Auto pushing orphaned message to next destination (#{message} -> #{destination.name})"
                          begin
                            destination.transmit(Utils.unpack(message))
                          rescue => e
                            error "Failed to auto push message (#{message}): #{e.class} - #{e}"
                          end
                        end
                      end
                    }
                  )
                  Carnivore::Utils.info "Registered new source: #{namespace}_#{key}_#{kind}"
                  if(kind.to_s == 'input')
                    opts.fetch(:callbacks, []).each do |klass_name|
                      klass = Utils.constantize(klass_name)
                      source.add_callback(klass_name, klass)
                    end
                  end
                end
              end
            end
          end
          Jackal::Utils.load_http_hook
          Carnivore.start!
        rescue => e
          $stderr.puts "Unexpected failure encountered: #{e.class}: #{e}"
          if(ENV['DEBUG'])
            $stderr.puts "#{e.class}: #{e}\n#{e.backtrace.join("\n")}"
          end
          exit -1
        end

      end
    end
  end
end
