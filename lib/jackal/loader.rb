require 'carnivore'
require 'jackal'

cli = Jackal::Cli.new
cli.parse_options
Carnivore::Config.configure(cli.config)
Carnivore::Config.auto_symbolize(true)

(Carnivore::Config.get(:jackal, :require) || []).each do |path|
  require path
end

begin
  Carnivore::Utils.symbolize_hash(Carnivore::Config.hash_dup).each do |key, opts|
    next if key == :jackal || !opts.is_a?(Hash)
    Carnivore::Utils.info "Processing: #{opts.inspect}"
    Carnivore.configure do
      opts.fetch(:sources, {}).each do |kind, source_args|
        source = Carnivore::Source.build(
          :type => source_args[:type].to_sym,
          :args => source_args.fetch(:args, {}).merge(:name => "#{key}_#{kind}")
        )
        Carnivore::Utils.info "Initialized new source: #{key}_#{kind}"
        if(kind == :input)
          opts.fetch(:callbacks, []).each do |klass_name|
            klass = klass_name.split('::').inject(
              Object.const_get(
                key.to_s.split('_').map(&:capitalize).join
              )
            ) do |memo, name|
              memo.const_get(name)
            end
            source.add_callback(klass_name, klass)
          end
        end
      end
    end
  end

  Carnivore.start!
rescue => e
  $stderr.puts "Unexpected failure encountered: #{e.class}: #{e}"
  if(ENV['DEBUG'])
    $stderr.puts "#{e.class}: #{e}\n#{e.backtrace.join("\n")}"
  end
  exit -1
end
