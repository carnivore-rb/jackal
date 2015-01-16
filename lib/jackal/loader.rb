require 'carnivore'
require 'jackal'

module Jackal
  class Loader
    class << self

      # @todo set configs as immutable once available
      def run!(opts)

        unless(ENV['JACKAL_TESTING_MODE'])
          Carnivore.configure!(opts[:config])
        end

        Celluloid.logger.level = Celluloid.logger.class.const_get(
          (opts[:verbosity] || Carnivore::Config[:verbosity] || :debug).to_s.upcase
        )

        Carnivore::Config.fetch(:jackal, :require, []).each do |path|
          require path
        end

        begin
          Carnivore::Utils.symbolize_hash(Carnivore::Config.data.to_smash).each do |namespace, args|
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
                      error "No callbacks matched message. Failed to process. Removed from bus. (#{message})"
                      message.confirm!
                    }
                  )
                  Carnivore::Utils.info "Registered new source: #{namespace}_#{key}_#{kind}"
                  if(kind == :input)
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
