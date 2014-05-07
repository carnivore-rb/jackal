require 'multi_json'
require 'carnivore/spec_helper'

Celluloid.logger.level = 0 if ENV['DEBUG']

# Default source setup higher than base carivore default
unless(ENV['CARNIVORE_SOURCE_SETUP'])
  ENV['CARNIVORE_SOURCE_SETUP'] = '0.5'
end

# Pass any jackal specific wait settings down to carnivore
ENV.each do |key, value|
  if(key.start_with?('JACKAL_SOURCE_'))
    carnivore_key = key.sub('JACKAL_SOURCE', 'CARNIVORE_SOURCE')
    ENV[carnivore_key] = value
  end
end

def payload_for(style, args={})
  file = "#{style}.json"
  path = [File.join(Dir.pwd, 'test/specs/payloads'), File.join(File.dirname(__FILE__), 'payloads')].map do |dir|
    if(File.exists?(full_path = File.join(dir, file)))
      full_path
    end
  end.compact.first
  if(path)
    if(args[:raw])
      MultiJson.load(File.read(path))
    else
      if(args[:nest])
        Jackal::Utils.new_payload(:test, args[:nest] => MultiJson.load(File.read(path)))
      else
        Jackal::Utils.new_payload(:test, File.read(path))
      end
    end
  else
    raise "Requested payload path for test does not exist: #{File.expand_path(path)}"
  end
end

def run_setup(config)
  path = File.join(Dir.pwd, 'test/specs/config', "#{config}.json")
  Carnivore::Config.configure(:config_path => path)
  runner = Thread.new do
    require 'jackal/loader'
  end
  source_wait(:setup)
  runner
end
