require 'carnivore'
require 'jackal'

module Jackal
  class Loader
    class << self

      # Configure the application
      #
      # @param opts [Hash]
      # @return [TrueClass]
      def configure!(opts)
        default_verbosity = nil
        if(ENV['JACKAL_TESTING_MODE'])
          if(!opts[:config])
            Carnivore.configure!(:verify)
          else
            Carnivore.configure!(opts[:config], :force)
          end
          default_verbosity = :fatal
        else
          Carnivore.configure!(opts[:config])
          Carnivore::Config.immutable!
          default_verbosity = :info
        end

        default_verbosity = :debug if ENV['DEBUG']
        const = opts.fetch(:verbosity,
          Carnivore::Config.fetch(:verbosity, default_verbosity)
        ).to_s.upcase

        Celluloid.logger.level = Celluloid.logger.class.const_get(const)
        true
      end

      # Scrub and type opts
      #
      # @param opts [Slop,Hash]
      # @return [Smash]
      def process_opts(opts)
        opts = opts.to_hash.to_smash
        opts.delete_if{|k,v| v.nil?}
        opts
      end

      # Run the jackal
      #
      # @param opts [Hash]
      def run!(opts)
        opts = process_opts(opts)
        configure!(opts)

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
                    :args => source_args.fetch(:args, {}).merge(
                      :name => "#{namespace}_#{key}_#{kind}",
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
                          else
                            warn "Failed to location destination for message forward! (Destination: #{destination} #{message})"
                          end
                        else
                          error "Cannot auto forward from output source. No messages should be encountered here! (#{message})"
                        end
                      }
                    )
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
          if(events_opts = Carnivore::Config.get(:jackal, :events))
            Carnivore.configure do
              Carnivore::Source.build(
                :type => events_opts[:type].to_sym,
                :args => events_opts.fetch(:args, {}).merge(
                  :name => :events
                )
              )
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
