require 'core_ext/hash/deep_merge'
require 'core_ext/hash/deep_symbolize_keys'
require 'core_ext/object/false'
require 'erb'
require 'rbconfig'

require 'travis/build/addons'
require 'travis/build/appliances'
require 'travis/build/git'
require 'travis/build/helpers'
require 'travis/build/stages'

require 'travis/build/script/android'
require 'travis/build/script/c'
require 'travis/build/script/clojure'
require 'travis/build/script/cpp'
require 'travis/build/script/crystal'
require 'travis/build/script/csharp'
require 'travis/build/script/d'
require 'travis/build/script/dart'
require 'travis/build/script/erlang'
require 'travis/build/script/elixir'
require 'travis/build/script/go'
require 'travis/build/script/groovy'
require 'travis/build/script/generic'
require 'travis/build/script/haskell'
require 'travis/build/script/haxe'
require 'travis/build/script/julia'
require 'travis/build/script/nix'
require 'travis/build/script/node_js'
require 'travis/build/script/objective_c'
require 'travis/build/script/perl'
require 'travis/build/script/perl6'
require 'travis/build/script/php'
require 'travis/build/script/pure_java'
require 'travis/build/script/python'
require 'travis/build/script/r'
require 'travis/build/script/ruby'
require 'travis/build/script/rust'
require 'travis/build/script/scala'
require 'travis/build/script/smalltalk'
require 'travis/build/script/shared/directory_cache'

module Travis
  module Build
    class Script
      TEMPLATES_PATH = File.expand_path('../templates', __FILE__)
      INTERNAL_RUBY_REGEX = ENV.fetch(
        'TRAVIS_INTERNAL_RUBY_REGEX',
        '^ruby-(2\.[0-2]\.[0-9]|1\.9\.3)'
      ).untaint
      DEFAULTS = {}

      class << self
        def defaults
          Git::DEFAULTS.merge(self::DEFAULTS)
        end
      end

      include Module.new { Stages::STAGES.each_slice(2).map(&:last).flatten.each { |stage| define_method(stage) {} } }
      include Appliances, DirectoryCache, Deprecation, Template

      attr_reader :sh, :data, :options, :validator, :addons, :stages
      attr_accessor :setup_cache_has_run_for

      def initialize(data)
        @data = Data.new({ config: self.class.defaults }.deep_merge(data.deep_symbolize_keys))
        @options = {}

        @sh = Shell::Builder.new
        @addons = Addons.new(self, sh, self.data, config)
        @stages = Stages.new(self, sh, config)
        @setup_cache_has_run_for = {}
      end

      def compile(ignore_taint = false)
        Shell.generate(sexp, ignore_taint)
      end

      def sexp
        run
        sh.to_sexp
      end

      def cache_slug_keys
        plain_env_vars = Array((config[:env] || []).dup).delete_if {|env| env.start_with? 'SECURE '}

        [
          'cache',
          config[:os],
          config[:dist],
          config[:osx_image],
          OpenSSL::Digest::SHA256.hexdigest(plain_env_vars.sort.join('='))
        ]
      end

      def cache_slug
        cache_slug_keys.compact.join('-')
      end

      def archive_url_for(bucket, version, lang = self.class.name.split('::').last.downcase, ext = 'bz2')
        sh.if "$(uname) = 'Linux'" do
          sh.raw "travis_host_os=$(lsb_release -is | tr 'A-Z' 'a-z')"
          sh.raw "travis_rel_version=$(lsb_release -rs)"
        end
        sh.elif "$(uname) = 'Darwin'" do
          sh.raw "travis_host_os=osx"
          sh.raw "travis_rel=$(sw_vers -productVersion)"
          sh.raw "travis_rel_version=${travis_rel%*.*}"
        end
        "archive_url=https://s3.amazonaws.com/#{bucket}/binaries/${travis_host_os}/${travis_rel_version}/$(uname -m)/#{lang}-#{version}.tar.#{ext}"
      end

      def debug_build_via_api?
        ! data.debug_options.empty?
      end

      private

        def config
          data.config
        end

        def debug
          if debug_build_via_api?
            sh.echo "Debug build initiated by #{data.debug_options[:created_by]}", ansi: :yellow
            if debug_quiet?
              sh.raw "travis_debug --quiet"
            else
              sh.raw "travis_debug"
            end

            sh.echo
            sh.echo "All remaining steps, including caching and deploy, will be skipped.", ansi: :yellow
          end
        end

        def run
          stages.run if apply :validate
          sh.raw template('footer.sh')
          # apply :deprecations
        end

        def header
          sh.raw(
            template(
              'header.sh',
              build_dir: BUILD_DIR,
              internal_ruby_regex: INTERNAL_RUBY_REGEX,
              root: '/',
              home: HOME_DIR
            ), pos: 0
          )
        end

        def configure
          apply :show_system_info
          apply :update_glibc
          apply :clean_up_path
          apply :fix_resolv_conf
          apply :fix_etc_hosts
          apply :no_ipv6_localhost
          apply :fix_etc_mavenrc
          apply :etc_hosts_pinning
          apply :fix_wwdr_certificate
          apply :put_localhost_first
          apply :home_paths
          apply :disable_initramfs
          apply :disable_ssh_roaming
          apply :debug_tools
          apply :npm_registry
          apply :rvm_use
        end

        def checkout
          apply :checkout
        end

        def export
          apply :env
        end

        def prepare
          apply :services
          apply :fix_ps4 # TODO if this is to fix an rvm issue (as the specs say) then should this go to Rvm instead?
        end

        def disable_sudo
          apply :disable_sudo
        end

        def reset_state
          if debug_build_via_api?
            raise "Debug payload does not contain 'previous_state' value." unless previous_state = data.debug_options[:previous_state]

            sh.echo
            sh.echo "This is a debug build. The build result is reset to its previous value, \\\"#{previous_state}\\\".", ansi: :yellow

            case previous_state
            when "passed"
              sh.export 'TRAVIS_TEST_RESULT', '0', echo: false
            when "failed"
              sh.export 'TRAVIS_TEST_RESULT', '1', echo: false
            when "errored"
              sh.raw 'travis_terminate 2'
            end
          end
        end

        def config_env_vars
          @config_env_vars ||= Build::Env::Config.new(data, config)
          Array(@config_env_vars.data[:env])
        end

        def host_os
          case RbConfig::CONFIG["host_os"]
          when /^(?i:linux)/
            '$(lsb_release -is | tr "A-Z" "a-z")'
          when /^(?i:darwin)/
            'osx'
          end
        end

        def rel_version
          case RbConfig::CONFIG["host_os"]
          when /^(?i:linux)/
            '$(lsb_release -rs)'
          when /^(?i:darwin)/
            '${$(sw_vers -productVersion)%*.*}'
          end
        end

        def debug_quiet?
          debug_build_via_api? && data.debug_options[:quiet]
        end

        def debug_enabled?
          ENV['TRAVIS_ENABLE_DEBUG_TOOLS'] == '1'
        end
    end
  end
end
