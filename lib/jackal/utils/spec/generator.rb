require 'erb'
require 'fileutils'
require 'optparse'

TEST_DIRS = 'test/specs/config'

OptionParser.new do |opts|
  opts.banner = "Usage: jackal-test generate [options]"

  opts.on("-sSNAME", "--service_name=SNAME", "Name of fission service to test (eg: Mail)") do |v|
    @orig_service_name = v.downcase
    @service_name = @orig_service_name.gsub(/-/, '_')
    @service_class_name = @service_name.split('_').map(&:capitalize).join
  end

  opts.on("-mMNAME", "--module_name=MNAME", "Name of particular class to test (eg: Mandrill)") do |v|
    @module_name = v.downcase
    @module_class_name = @module_name.capitalize
  end

end.parse!

@callback_type  = ($0 =~ /fission-test/) ? 'fission' : 'jackal'
@callback_class = @callback_type.capitalize

# ----------------------------------------------------------------------
# ensure dependencies are present in Gemfile
raise 'Ensure Gemfile exists' unless File.exists?('Gemfile')
gemfile = File.read('Gemfile')
lines = ["gem 'carnivore-actor'", "gem 'minitest'", "gem 'pry'"]
lines.select!{ |l| !gemfile[l] } # only append items not already present

unless lines.empty?
  File.open('Gemfile', 'a') do |f|
    f << "\n"
    lines.each { |l| f << (l + "\n") }
  end
end

# ----------------------------------------------------------------------
# Create test directory structure
FileUtils.mkdir_p(TEST_DIRS)

# ----------------------------------------------------------------------
# Write out fission config file
template = File.expand_path("../templates/generator/config.rb.erb", __FILE__)
conf = ERB.new(File.read(template)).result

conf_file = File.join(Dir.pwd, TEST_DIRS, "#{@module_name}.rb")
raise 'Config file already exists' if File.exists?(conf_file)
File.write(conf_file, conf)

# ----------------------------------------------------------------------
# Write out minitest (via fission-test) spec file scaffold

supervisor_name = (@callback_type == 'fission') ? @service_name : "jackal_#{@service_name}_input"
spec = <<SPEC
require '#{@callback_type}-#{@orig_service_name}'
require 'pry'

# To stub out an api call for your callback
class #{@callback_class}::#{@service_class_name}::#{@module_class_name}
  attr_accessor :test_payload

  #def api_call(args)
  #  test_payload.set(:args, args)
  #end
end

describe #{@callback_class}::#{@service_class_name}::#{@module_class_name} do

  before do
    @runner = run_setup(:#{@module_name})
    track_execution(#{@callback_class}::#{@service_class_name}::#{@module_class_name})
  end

  after do
    @runner.terminate
  end

  let(:actor) { Carnivore::Supervisor.supervisor[:#{supervisor_name}] }

  it 'executes with empty payload' do
    result = transmit_and_wait(actor, payload)
    (!!result).must_equal true
    callback_executed?(result).must_equal true
  end

  private

  # payload to send for callback execution
  def payload
    Jackal::Utils.new_payload(:test, Smash.new)
  end

end
SPEC

filename = "#{@service_name}_spec.rb"
spec_file = File.join(Dir.pwd, 'test/specs', filename)
raise 'Spec file already exists' if File.exists?(spec_file)
File.write(spec_file, spec)
