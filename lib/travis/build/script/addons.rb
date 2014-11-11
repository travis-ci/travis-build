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

        def run_stage(stage)
          addons.each do |addon|
            addon.send(stage) if run_stage?(addon, stage)
          end
        end

        private

          def addons
            @addons ||= addon_config.map { |name, config| addon(name, config) }.compact
          end

          def run_addon?(const)
            !data.disable_sudo? || const::SUPER_USER_SAFE
          end

          def run_stage?(addon, stage)
            addon.respond_to?(stage) && (!addon.respond_to?(:"#{stage}?") || addon.respond_to?(:"#{stage}?"))
          end

          def addon(name, config)
            const = self.class.const_get(name.to_s.camelize)
            const.new(sh, data, config) if const && run_addon?(const)
          rescue NameError
          end

          def addon_config
            config[:addons] || {}
          end
      end
    end
  end
end
