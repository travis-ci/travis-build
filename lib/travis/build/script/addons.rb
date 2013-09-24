require 'travis/build/script/addons/deploy'
require 'travis/build/script/addons/firefox'
require 'travis/build/script/addons/hosts'
require 'travis/build/script/addons/sauce_connect'
require 'travis/build/script/addons/code_climate'
require 'travis/build/script/addons/packages'

module Travis
  module Build
    class Script
      module Addons
        MAP = {
          deploy:        Deploy,
          firefox:       Firefox,
          hosts:         Hosts,
          sauce_connect: SauceConnect,
          code_climate:  CodeClimate,
          packages:      Packages,
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
