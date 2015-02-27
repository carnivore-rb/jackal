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

# Fetch test payload and create new payload
#
# @param style [String, Symbol] name of payload
# @param args [Hash]
# @option args [TrueClass, FalseClass] :raw return loaded payload only
# @option args [String, Symbol] :nest place loaded payload within key namespace in hash
# @return [Hash] new payload
# @note `style` is name of test payload without .json extension. Will
# search 'test/specs/payload' from CWD first, then fallback to
# 'payloads' directory within the directory of this file
def payload_for(style, args={})
  file = "#{style}.json"
  path = [File.join(Dir.pwd, 'test/specs/payloads'), Jackal::Utils::Spec.payload_storage].flatten.compact.map do |dir|
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
        Jackal::Utils.new_payload(:test, MultiJson.load(File.read(path)))
      end
    end
  else
    raise "Requested payload path for test does not exist: #{path ? File.expand_path(path) : 'no path discovered'}"
  end
end

# Configure using custom configuration JSON within config
# directory of current test
#
# @param config [String, Symbol] name of configuration file
# @return [Thread] thread with running source
def run_setup(config)
  config_dir = File.join(Dir.pwd, 'test', 'specs', 'config')
  path = Dir.glob(File.join(config_dir, "#{config}*")).first

  msg = "No file matching #{config} found in #{config_dir}"
  raise msg unless path

  Thread.abort_on_exception = true
  runner = Thread.new do
    Jackal::Loader.run!(:config => path)
  end
  source_wait(:setup)
  runner
end
