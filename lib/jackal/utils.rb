require 'jackal'

module Jackal
  # Helper utilities
  module Utils

    autoload :Spec, 'jackal/utils/spec'
    autoload :Payload, 'jackal/utils/payload'
    autoload :Config, 'jackal/utils/config'
    autoload :HttpApi, 'jackal/utils/http_api'

    extend Payload

  end
end
