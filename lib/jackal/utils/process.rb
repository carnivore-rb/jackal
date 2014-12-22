require 'jackal'
require 'fileutils'
require 'childprocess'
require 'shellwords'
require 'tempfile'

module Jackal
  module Utils
    class Process

      # Create new instance
      #
      # @return [self]
      def initialize
        @storage_directory = Carnivore::Config.fetch(
          :fission, :utils, :process_manager, :storage,
          '/tmp/fission/process_manager'
        )
        FileUtils.mkdir_p(@storage_directory)
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
          yield ChildProcess.build(*command)
        end
        true
      end

      # Temporary IO for logging
      #
      # @param args [String] argument list joined for filename
      # @return [IO]
      def create_io_tmp(*args)
        path = File.join(@storage_directory, args.join('-'))
        FileUtils.mkdir_p(File.dirname(path))
        t_file = File.open(path, 'w+')
        t_file.sync
        t_file
      end

    end
  end
end
