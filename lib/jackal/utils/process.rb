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

      # @return [Smash] manager configuration
      attr_reader :configuration
      # @return [String] storage directory path
      attr_reader :storage_directory

      # Create new instance
      #
      # @param config [Smash] process manager configuration
      # @return [self]
      def initialize(config={})
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
      # @return [TrueClass]
      def process(identifier, *command)
        if(command.size == 1)
          command = Shellwords.shellsplit(command.first)
        end
        if(block_given?)
          if(configuration[:spawn])
            yield ChildProcess::Unix::PosixSpawnProcess.new(command)
          else
            yield ChildProcess.build(*command)
          end
        else
          raise ArgumentError.new('Expecting block but no block provided!')
        end
        true
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

    end
  end
end
