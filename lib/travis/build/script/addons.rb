require 'active_support/core_ext/string/inflections.rb'
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
      class Addons
        attr_reader :sh, :data, :config

        def initialize(sh, data, config)
          @sh = sh
          @data = data
          @config = config
        end

        def run(stage)
          addons(stage).each do |addon|
            addon.send(stage) if run_stage?(addon, stage)
          end
        end

        private

          def addons(stage)
            @addons ||= (config[:addons] || {}).map do |name, config|
              addon(stage, name, config)
            end.compact
          end

          def addon(stage, name, config)
            const = self.class.const_get(name.to_s.camelize)
            const.new(sh, data, merge_config(stage, config)) if const && run_addon?(const)
          end

          def merge_config(stage, other)
            [:before, :after].each do |prefix|
              key = :"#{prefix}_#{stage}"
              value = config[key]
              other = other.merge(key => value) if value
            end
            other
          end

          def run_addon?(const)
            !data.paranoid_mode? || const::SUPER_USER_SAFE
          end

          def run_stage?(addon, stage)
            addon.respond_to?(stage) && (!addon.respond_to?(:"#{stage}?") || addon.respond_to?(:"#{stage}?"))
          end
      end
    end
  end
end
