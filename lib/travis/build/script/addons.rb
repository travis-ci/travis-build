require 'travis/build/script/addons/sauce_connect'

module Travis
  module Build
    class Script
      module Addons
        MAP = {
          :sauce_connect => SauceConnect
        }

        def run_addons
          addons.each do |addon|
            addon.run
          end
        end

        def addons
          @addons ||= (config[:addons] || {}).map do |name, addon_config|
            init_addon(name, addon_config)
          end
        end

        def init_addon(name, config)
          MAP[name].new(self, config)
        end
      end
    end
  end
end
