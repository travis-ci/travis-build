require 'travis/build/script/templates'

module Travis
  module Build
    class Script
      class Addons
        class Base
          include Templates

          attr_reader :sh, :data, :config

          def initialize(sh, data, config)
            @sh = sh
            @data = data
            @config = normalize_config(config)
          end

          def normalize_config(config)
            config.is_a?(String) ? config.to_s : config
          end
        end
      end
    end
  end
end

