require 'core_ext/hash/deep_merge'
require 'core_ext/hash/deep_symbolize_keys'
require 'core_ext/object/false'
require 'erb'

require 'travis/build/addons'
require 'travis/build/appliances'
require 'travis/build/helpers'
require 'travis/build/stages'

require 'travis/build/script/android'
require 'travis/build/script/c'
require 'travis/build/script/cpp'
require 'travis/build/script/clojure'
require 'travis/build/script/erlang'
require 'travis/build/script/go'
require 'travis/build/script/groovy'
require 'travis/build/script/generic'
require 'travis/build/script/haskell'
require 'travis/build/script/node_js'
require 'travis/build/script/objective_c'
require 'travis/build/script/perl'
require 'travis/build/script/php'
require 'travis/build/script/pure_java'
require 'travis/build/script/python'
require 'travis/build/script/ruby'
require 'travis/build/script/rust'
require 'travis/build/script/scala'
require 'travis/build/script/shared/directory_cache'
require 'travis/build/script/shared/git'

module Travis
  module Build
    class Script
      TEMPLATES_PATH = File.expand_path('../templates', __FILE__)
      DEFAULTS = {}

      class << self
        def defaults
          Git::DEFAULTS.merge(self::DEFAULTS)
        end
      end

      include Module.new { Stages::STAGES.values.flatten.each { |stage| define_method(stage) {} } }
      include Appliances, DirectoryCache, Deprecation, Template

      attr_reader :sh, :data, :options, :validator, :addons, :stages

      def initialize(data)
        @data = Data.new({ config: self.class.defaults }.deep_merge(data.deep_symbolize_keys))
        @options = {}

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
          sh.raw template('header.sh', build_dir: BUILD_DIR), pos: 0
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
          apply :fix_ps4 # TODO if this is to fix an rvm issue (as the specs say) then should this go to Rvm instead?
          apply :disable_sudo
        end
    end
  end
end
