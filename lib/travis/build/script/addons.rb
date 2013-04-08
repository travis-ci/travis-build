require 'travis/build/script/addons/sauce_connect'
require 'travis/build/script/addons/firefox'

module Travis
  module Build
    class Script
      module Addons
        MAP = {
          :sauce_connect => SauceConnect,
          :firefox => Firefox,
        }

        def run_addons(stage)
          addons.each do |addon|
            addon.send(stage) if addon.respond_to?(stage)
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
