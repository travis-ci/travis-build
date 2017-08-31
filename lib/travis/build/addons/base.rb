require 'travis/build/helpers/template'

module Travis
  module Build
    class Addons
      class Base
        include Template

        attr_reader :script, :sh, :data, :config, :conditional

        def initialize(script, sh, data, config)
          @script = script
          @sh = sh
          @data = data
          @config = normalize_config(config)

          @conditional = Travis::Build::Addons::Conditional.new(sh, self, config)
        end

        def normalize_config(config)
          case config
          when Fixnum, Float, String, Array, Hash
            config
          else
            {}
          end
        end

        def conditions
          conditional.conditions
        end
      end
    end
  end
end
