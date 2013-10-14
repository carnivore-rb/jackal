require 'carnivore'
require 'carnivore-runner/cli'

cli = CarnivoreRunner::Cli.new
cli.parse_options
Carnivore::Config.configure(cli.config)
Carnivore::Config.auto_symbolize(true)

begin
  Carnivore::Config.get(:sources).each do |name, opts|
    Carnivore.configure do
      source = Carnivore::Source.build(
        :type => opts[:type].to_sym,
        :args => opts[:args].merge(:name => name)
      )
      Carnivore::Config.get(:callbacks, name).each do |klass_name|
        klass = CarnivoreRunner.const_get(klass_name)
        source.add_callback(klass_name, klass)
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
