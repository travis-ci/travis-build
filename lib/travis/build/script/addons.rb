require 'travis/build/script/addons/artifacts'
require 'travis/build/script/addons/code_climate'
require 'travis/build/script/addons/coverity_scan'
require 'travis/build/script/addons/deploy'
require 'travis/build/script/addons/firefox'
require 'travis/build/script/addons/hosts'
require 'travis/build/script/addons/postgresql'
require 'travis/build/script/addons/sauce_connect'
require 'travis/build/script/addons/ssh_known_hosts'

module Travis
  module Build
    class Script
      module Addons
        MAP = {
          artifacts:       Artifacts,
          code_climate:    CodeClimate,
          coverity_scan:   CoverityScan,
          deploy:          Deploy::Group,
          firefox:         Firefox,
          hosts:           Hosts,
          postgresql:      Postgresql,
          sauce_connect:   SauceConnect,
          ssh_known_hosts: SshKnownHosts,
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
          MAP[name] && MAP[name].new(sh, config)
        end

        def can_run?(addon, stage)
          return false if !addon.respond_to?(stage)

          if !data.paranoid_mode?
            true
          elsif data.paranoid_mode? && addon.class::SUPER_USER_SAFE
            true
          else
            false
          end
        end
      end
    end
  end
end
