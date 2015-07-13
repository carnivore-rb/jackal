require 'bogo-cli'
require 'fileutils'
require 'jackal'

module Jackal
  module Utils
    module Spec
      class Generator < Bogo::Cli::Command
        TEST_DIRS = 'test/specs/config'

        def initialize(*_)
          super

          @orig_service_name = options[:service_name].downcase
          @service_name = Bogo::Utility.snake(@orig_service_name)
          @service_class_name = Bogo::Utility.camel(@service_name)

          @module_name = options[:module_name].downcase
          @module_class_name = Bogo::Utility.camel(@module_name)

          @callback_type   = 'jackal'
          @supervisor_name = "jackal_#{@service_name}_input"
        end

        def execute!
          # ensure dependencies are present in Gemfile
          update_gemfile
          # Create test directory structure
          FileUtils.mkdir_p(TEST_DIRS)

          conf_path = File.join(Dir.pwd, TEST_DIRS, "#{@module_name}.rb")
          write_file(conf_path, config_file_content)

          spec_path = File.join(Dir.pwd, 'test/specs', "#{@service_name}_spec.rb")
          write_file(spec_path, spec_file_content)
        end


        def config_file_content
          <<-TEXT
Configuration.new do
  jackal do
    require ["carnivore-actor", "jackal-#{@orig_service_name}"]

    mail do
      config do
      end

      sources do
        input  { type 'actor' }
        output { type 'spec' }
      end

      callbacks ['Jackal::#{@service_class_name}::#{@module_class_name}']
    end
  end
end
TEXT
        end

        def spec_file_content
          <<TEXT
require '#{@callback_type}-#{@orig_service_name}'
require 'pry'

# To stub out an api call for your callback
class #{callback_class}::#{@service_class_name}::#{@module_class_name}
  attr_accessor :test_payload

  #def api_call(args)
  #  test_payload.set(:args, args)
  #end
end

describe #{callback_class}::#{@service_class_name}::#{@module_class_name} do

  before do
    @runner = run_setup(:#{@module_name})
    track_execution(#{callback_class}::#{@service_class_name}::#{@module_class_name})
  end

  after do
    @runner.terminate
  end

  let(:actor) { Carnivore::Supervisor.supervisor[:#{@supervisor_name}] }

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
TEXT
        end

        private

        def callback_class
          @callback_class ||= Bogo::Utility.camel(@callback_type)
        end

        def update_gemfile
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
        end

        def write_file(path, content)
          raise "Config file (#{path}) already exists" if File.exists?(path)
          File.write(path, content)
        end

      end
    end
  end
end
