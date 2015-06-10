require 'multi_json'
require 'carnivore/spec_helper'

Celluloid.logger.level = ENV['DEBUG'] ? 0 : 4

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
    Jackal::Utils::Spec.system_runner.run!(:config => path)
  end
  source_wait(:setup)
  runner
end

# Store callback execution flag in payload to test callback validity

# @klass callback class to inject execution tracking
def track_execution(klass)
  alias_name = :execute_orig
  # Ensure this is called only once within test suite
  return if klass.method_defined?(alias_name)

  klass.send(:alias_method, alias_name, :execute)
  klass.send(:define_method, :execute) do |message|
    message.args['message']['executed'] = true
    execute_orig(message)
  end
end

# Convenience method to check whether or not callback was executed

# @param payload [Smash] payload result from callback execution
# @return [Boolean] callback execution status
def callback_executed?(payload)
  payload.get(:executed) == true
end

# Convenience method for sending an actor a payload and waiting for result

# @param actor [Carnivore::Source::Actor] actor to receive payload
# @param payload [Smash] payload to send actor
# @param wait_time [Numeric] max time to wait for message result (default 1)
# @return [Smash] payload result
def transmit_and_wait(actor, payload, wait_time = 1)
  actor.callbacks.each do |c_name|
    callback = actor.callback_supervisor[actor.callback_name(c_name)]
    if(callback.respond_to?(:test_payload=))
      callback.test_payload = Smash.new
    end
  end
  actor.transmit(payload)
  source_wait(wait_time) { !MessageStore.messages.empty? }
  actor.callbacks.each do |c_name|
    callback = actor.callback_supervisor[actor.callback_name(c_name)]
    if(callback.respond_to?(:test_payload=))
      unless(MessageStore.messages.empty?)
        MessageStore.messages.first.deep_merge!(callback.test_payload)
      end
      callback.test_payload = nil
    end
  end
  MessageStore.messages.pop
end
