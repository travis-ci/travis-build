require 'core_ext/hash/deep_merge'
require 'core_ext/hash/deep_symbolize_keys'
require 'core_ext/object/false'
require 'erb'

require 'travis/build/script/addons'
require 'travis/build/script/appliances'
require 'travis/build/script/helpers'
require 'travis/build/script/lang'
require 'travis/build/script/stages'

module Travis
  module Build
    class Script
      TEMPLATES_PATH = File.expand_path('../script/templates', __FILE__)

      STAGES = {
        builtin: [:configure, :checkout, :prepare, :setup, :export, :announce],
        custom:  [:before_install, :install, :before_script, :script, :after_script],
        result:  [:after_success, :after_failure],
        finish:  [:finish]
      }

      class << self
        def defaults
          Git::DEFAULTS.merge(self::DEFAULTS)
        end
      end

      include Module.new { STAGES.values.flatten.each { |stage| define_method(stage) {} } }
      include Appliances, DirectoryCache, Deprecation, Template

      attr_reader :sh, :data, :options, :validator, :addons, :stages

      def initialize(data, options = {})
        @data = Data.new({ config: self.class.defaults }.deep_merge(data.deep_symbolize_keys))
        @options = options
        @sh = Shell::Builder.new

        @addons = Addons.new(sh, @data, config)
        @stages = Stages.new(self, sh, config)
      end

      def compile
        Shell.generate(sexp)
      end

      def sexp
        run
        sh.to_sexp
      end

      def cache_slug
        'cache'
      end

      private

        def config
          data.config
        end

        def run
          stages.run if apply :validate
          sh.raw template('footer.sh')
          apply :deprecations
          sh.raw template('header.sh'), pos: 0
        end

        def configure
          apply :fix_resolv_conf
          apply :fix_etc_hosts
        end

        def checkout
          apply :checkout
        end

        def export
          apply :env
        end

        def prepare
          apply :services
          apply :setup_apt_cache
          apply :fix_ps4
          apply :disable_sudo
        end
    end
  end
end
