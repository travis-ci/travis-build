require 'active_support/core_ext/string/inflections.rb'
require 'travis/build/addons/apt'
require 'travis/build/addons/apt_packages'
require 'travis/build/addons/apt_retries'
require 'travis/build/addons/snaps'
require 'travis/build/addons/artifacts'
require 'travis/build/addons/chrome'
require 'travis/build/addons/code_climate'
require 'travis/build/addons/coverity_scan'
require 'travis/build/addons/deploy'
require 'travis/build/addons/firefox'
require 'travis/build/addons/homebrew'
require 'travis/build/addons/hostname'
require 'travis/build/addons/hosts'
require 'travis/build/addons/mariadb'
require 'travis/build/addons/rethinkdb'
require 'travis/build/addons/postgresql'
require 'travis/build/addons/sauce_connect'
require 'travis/build/addons/jwt'
require 'travis/build/addons/ssh_known_hosts'
require 'travis/build/addons/sonarcloud'
require 'travis/build/addons/sonarqube'
require 'travis/build/addons/browserstack'
require 'travis/build/addons/srcclr'

module Travis
  module Build
    class Addons
      attr_reader :script, :sh, :data, :config

      def initialize(script, sh, data, config)
        @script = script
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
          addon.respond_to?(stage) && (!addon.respond_to?(:"#{stage}?") || addon.send(:"#{stage}?"))
        end

        def addon(name, config)
          const = self.class.const_get(name.to_s.camelize)
          const.new(script, sh, data, config) if const && run_addon?(const)
        rescue NameError
        end

        def addon_config
          config[:addons] || {}
        end
    end
  end
end
