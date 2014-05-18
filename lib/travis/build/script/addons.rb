require 'travis/build/script/addons/artifacts'
require 'travis/build/script/addons/code_climate'
require 'travis/build/script/addons/deploy'
require 'travis/build/script/addons/firefox'
require 'travis/build/script/addons/hosts'
require 'travis/build/script/addons/postgresql'
require 'travis/build/script/addons/sauce_connect'
require 'travis/build/script/addons/coverity_scan'

module Travis
  module Build
    class Script
      module Addons
        MAP = {
          artifacts:     Artifacts,
          code_climate:  CodeClimate,
          deploy:        Deploy,
          firefox:       Firefox,
          hosts:         Hosts,
          postgresql:    Postgresql,
          sauce_connect: SauceConnect,
          coverity_scan: CoverityScan,
        }

        def run_addons(stage)
          addons.each do |addon|
            addon.send(stage) if can_run?(addon, stage)
          end
        end

        def addons
          @addons ||= (config[:addons] || {}).map do |name, addon_config|
            init_addon(name, addon_config)
          end.compact
        end

        def init_addon(name, config)
          MAP[name] && MAP[name].new(self, config)
        end

        def can_run?(addon, stage)
          return false if !addon.respond_to?(stage)

          if !data.paranoid_mode?
            true
          elsif data.paranoid_mode? && !addon::REQUIRES_SUPER_USER
            true
          else
            false
          end
        end
      end
    end
  end
end
