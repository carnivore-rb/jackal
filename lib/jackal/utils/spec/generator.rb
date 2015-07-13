require 'bogo-cli'
require 'fileutils'
require 'jackal'

module Jackal
  module Utils
    module Spec
      # Test files generator
      class Generator < Bogo::Cli::Command

        # Test directory path
        TEST_DIR = 'test/specs'
        # Test configuration directory path
        TEST_CONFIG_DIR = 'test/specs/config'
        # Lines required within Gemfile
        GEMFILE_LINES = [
          "gem 'carnivore-actor'",
          "gem 'minitest'",
          "gem 'pry'"
        ]

        # Create new instance
        #
        # @return [self]
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

        # Generate test files
        #
        # @return [TrueClass]
        def execute!
          ui.info 'Generating jackal test files'

          # ensure dependencies are present in Gemfile
          run_action 'Update Gemfile contents' do
            update_gemfile
            nil
          end

          run_action 'Create testing directory structure' do
            # Create test directory structure
            [TEST_DIR, TEST_CONFIG_DIR].each do |dir|
              FileUtils.mkdir_p(dir)
            end
            nil
          end

          run_action 'Write test configuration file' do
            conf_path = File.join(Dir.pwd, TEST_CONFIG_DIR, "#{@module_name}.rb")
            write_file(conf_path, config_file_content)
            nil
          end

          run_action 'Write default test spec file' do
            spec_path = File.join(Dir.pwd, TEST_DIR, "#{@service_name}_spec.rb")
            write_file(spec_path, spec_file_content)
            nil
          end

          ui.info 'Jackal test file generation complete!'
          true
        end

        # Configuration file content
        #
        # @return [String]
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

        # Spec file content
        #
        # @return [String]
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

        # @return [String] callback class name
        def callback_class
          @callback_class ||= Bogo::Utility.camel(@callback_type)
        end

        # Update the contents of the Gemfile with required items
        #
        # @return [TrueClass]
        def update_gemfile
          raise Errno::ENOENT.new('Gemfile (ensure file exists)') unless File.exists?('Gemfile')
          gemfile = File.read('Gemfile')
          lines = GEMFILE_LINES.select{ |l| !gemfile[l] } # only append items not already present

          unless(lines.empty?)
            File.open('Gemfile', 'a') do |f|
              f << "\n"
              lines.each { |l| f << (l + "\n") }
            end
          end
          true
        end

        # Write file content to given path if file does not already
        # exist
        #
        # @param path [String] path to write
        # @param content [String] file content
        # @return [Integer] number of bytes written
        def write_file(path, content)
          raise Errno::EEXIST.new(path) if File.exists?(path)
          File.write(path, content)
        end

      end
    end
  end
end
