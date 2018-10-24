require 'forwardable'
require 'travis/build/helpers/template'

module Travis
  module Build
    class Addons
      class Base
        attr_reader :script, :sh, :data, :config

        extend Forwardable
        def_delegators :script, :bash

        def initialize(script, sh, data, config)
          @script = script
          @sh = sh
          @data = data
          @config = normalize_config(config)
        end

        def normalize_config(config)
          case config
          when Integer, Float, String, Array, Hash
            config
          else
            {}
          end
        end
      end
    end
  end
end
