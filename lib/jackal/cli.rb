require 'mixlib/cli'

module Jackal
  class Cli
    include Mixlib::CLI

    option(:config_path,
      :short => '-c FILE',
      :long => '--config FILE',
      :required => true,
      :description => 'Path to configuration file'
    )

  end
end
