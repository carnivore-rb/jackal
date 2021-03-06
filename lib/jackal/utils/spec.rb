require 'jackal'

module Jackal
  module Utils
    # Testing helpers
    module Spec
      autoload :CallbackLocal, 'jackal/utils/spec/callback_local'
      autoload :Generator, 'jackal/utils/spec/generator'

      class << self

        # @return [Class] class used to run subsystem
        attr_accessor :system_runner

        # Valid directories for test payloads
        #
        # @param args [String] list of directories to append
        # @return [Array<String>]
        def payload_storage(*args)
          unless(@_payload_dirs)
            @_payload_dirs = []
          end
          unless(args.empty?)
            @_payload_dirs += args.find_all do |dir_path|
              File.directory?(dir_path)
            end
            @_payload_dirs.uniq!
          end
          @_payload_dirs
        end

      end
    end
  end
end

Jackal::Utils::Spec.system_runner = Jackal::Loader
