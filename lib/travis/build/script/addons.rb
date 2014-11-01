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
          addons(stage).each do |addon|
            addon.send(stage) if run_addon?(addon, stage)
          end
        end

        def addons(stage)
          @addons ||= (config[:addons] || {}).map do |name, config|
            addon(stage, name, config)
          end.compact
        end

        def addon(stage, name, config)
          MAP[name].new(sh, data, merge_config(stage, config)) if MAP[name]
        end

        def merge_config(stage, other)
          [:before, :after].each do |prefix|
            key = :"#{prefix}_#{stage}"
            value = config[key]
            other = other.merge(key => value) if value
          end
          other
        end

        def run_addon?(addon, stage)
          if !addon.respond_to?(stage)
            false
          elsif !data.paranoid_mode? || addon.class::SUPER_USER_SAFE
            true
          else
            false
          end
        end
      end
    end
  end
end
