require 'jackal'
require 'fileutils'
require 'childprocess'
require 'shellwords'
require 'tempfile'

module Jackal
  module Utils
    class Process

      # Default path for IO tmp files
      DEFAULT_STORAGE_DIRECTORY = '/tmp/jackal-process-manager'

      # Environment variables that should be removed from process environment
      BLACKLISTED_ENV = ['GIT_DIR']

      # @return [Smash] manager configuration
      attr_reader :configuration
      # @return [String] storage directory path
      attr_reader :storage_directory

      # Create new instance
      #
      # @param config [Smash] process manager configuration
      # @return [self]
      def initialize(config={})
        @base_env = ENV.to_hash
        @configuration = config.to_smash
        @storage_directory = configuration.fetch(
          :storage_directory, DEFAULT_STORAGE_DIRECTORY
        )
        FileUtils.mkdir_p(storage_directory)
      end

      # Create new process
      #
      # @param identifier [String] command identifier (compat argument)
      # @param command [String] command in single string or splatted array
      # @yieldparam [ChildProcess]
      # @return [ChildProcess] allows for result inspection if desired
      def process(identifier, *command)
        _proc = nil
        if(command.size == 1)
          command = Shellwords.shellsplit(command.first)
        end
        if(block_given?)
          if(configuration[:spawn])
            _proc = clean_env!{ ChildProcess::Unix::PosixSpawnProcess.new(command) }
            scrub_env(_proc.environment)
            clean_env!{ yield _proc }
          else
            _proc = clean_env!{ ChildProcess.build(*command) }
            scrub_env(_proc.environment)
            clean_env!{ yield _proc }
          end
        else
          raise ArgumentError.new('Expecting block but no block provided!')
        end
        _proc
      end

      # Temporary IO for logging
      #
      # @param args [String] argument list joined for filename
      # @return [IO]
      def create_io_tmp(*args)
        path = File.join(storage_directory, args.join('-'))
        FileUtils.mkdir_p(File.dirname(path))
        t_file = File.open(path, 'w+')
        t_file.sync
        t_file
      end

      private

      # Remove environment variables that are known should _NOT_ be set
      #
      # @yield execute block within scrubbed environment
      def clean_env!
        ENV.replace(@base_env.dup)
        scrub_env(ENV)
        if(defined?(Bundler))
          Bundler.with_clean_env{ yield }
        else
          yield
        end
      end

      # Scrubs configured keys from hash
      #
      # @param env [Hash] hash to scrub
      # @return [TrueClass]
      def scrub_env(env)
        [
          BLACKLISTED_ENV,
          Carnivore::Config.get(
            :jackal, :utils, :process_manager, :blacklisted_env
          )
        ].flatten.compact.each do |key|
          env.delete(key)
        end
        true
      end

    end
  end
end
