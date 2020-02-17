require 'core_ext/hash/deep_merge'
require 'core_ext/hash/deep_symbolize_keys'
require 'core_ext/object/false'
require 'erb'
require 'rbconfig'
require 'date'

require 'travis/build/addons'
require 'travis/build/appliances'
require 'travis/build/errors'
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
require 'travis/build/script/elm'
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
      DEFAULTS = {}

      TRAVIS_FUNCTIONS = %w[
        travis_apt_get_update
        travis_assert
        travis_bash_qsort_numeric
        travis_cleanup
        travis_cmd
        travis_decrypt
        travis_download
        travis_find_jdk_path
        travis_fold
        travis_footer
        travis_install_jdk
        travis_internal_ruby
        travis_jigger
        travis_jinfo_file
        travis_nanoseconds
        travis_remove_from_path
        travis_result
        travis_retry
        travis_setup_env
        travis_setup_java
        travis_temporary_hacks
        travis_terminate
        travis_time_finish
        travis_time_start
        travis_trace_span
        travis_vers2int
        travis_wait
        travis_whereami
      ].freeze
      private_constant :TRAVIS_FUNCTIONS

      class << self
        def defaults
          Git::DEFAULTS.merge(self::DEFAULTS)
        end
      end

      include Module.new do
        Travis::Build::Stages::STAGES.map(&:name).flatten.each do |stage|
          define_method(stage) {}
        end
      end

      include Travis::Build::Appliances, Travis::Build::Script::DirectoryCache
      include Travis::Build::Deprecation, Travis::Build::Bash

      attr_reader :sh, :raw_data, :data, :options, :validator, :addons, :stages
      attr_reader :root, :home_dir, :build_dir
      attr_accessor :setup_cache_has_run_for

      def initialize(data)
        @raw_data = data.deep_symbolize_keys
        raw_config = @raw_data[:config]
        lang_sym = raw_config.fetch(:language,"").to_sym
        @data = Data.new({
          config: self.class.defaults,
          language_default_p: !raw_config[lang_sym]
        }.deep_merge(self.raw_data))
        @options = {}

        tracing_enabled = data[:trace]

        @root = '/'
        @home_dir = HOME_DIR
        @build_dir = BUILD_DIR

        @sh = Shell::Builder.new(tracing_enabled)
        @addons = Addons.new(self, sh, self.data, config)
        @stages = Stages.new(self, sh, config)
        @setup_cache_has_run_for = {}
      end

      def compile(ignore_taint = false)
        nodes = sexp
        Shell.generate(nodes, ignore_taint)
      rescue Travis::Shell::Generator::TaintedOutput => to
        log_tainted_nodes(nodes)
        raise to
      rescue Exception => e
        event = Travis::Build.config.sentry_dsn.empty? ? nil : Raven.capture_exception(e)

        unless Travis::Build.config.dump_backtrace?
          Travis::Build.logger.error(e)
          Travis::Build.logger.error(e.backtrace)
        end

        if ENV['RACK_ENV'] == 'development'
          raise e
        end

        show_compile_error_msg(e, event)
      end

      def sexp
        run
        sh.to_sexp
      end

      def log_tainted_nodes(nodes)
        return unless Travis::Build.config.tainted_node_logging_enabled?
        tainted_values = nodes.flatten.select(&:tainted?)
        Travis::Build.logger.error(
          "nodes contain tainted value(s) #{tainted_values.inspect}"
        )
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

      def archive_url_for(bucket, version, lang = lang_name, ext = 'bz2')
        file_name = "#{[lang, version].compact.join("-")}.tar.#{ext}"
        sh.if "$(uname) = 'Linux'" do
          sh.raw "travis_host_os=$(lsb_release -is | tr 'A-Z' 'a-z')"
          sh.raw "travis_rel_version=$(lsb_release -rs)"
        end
        sh.elif "$(uname) = 'Darwin'" do
          sh.raw "travis_host_os=osx"
          sh.raw "travis_rel=$(sw_vers -productVersion)"
          sh.raw "travis_rel_version=${travis_rel%*.*}"
        end
        lang = 'python' if lang.start_with?('py')
        "archive_url=https://#{lang_archive_prefix(lang, bucket)}/binaries/${travis_host_os}/${travis_rel_version}/$(uname -m)/#{file_name}"
      end

      def lang_archive_prefix(lang, bucket)
        custom_archive = ENV["TRAVIS_BUILD_LANG_ARCHIVES_#{lang}".upcase]
        unless custom_archive.to_s.empty?
          return custom_archive.output_safe
        end

        case Travis::Build.config.lang_archive_host
        when 'gcs'
          "storage.googleapis.com/travis-ci-language-archives/#{lang}"
        when 's3'
          "s3.amazonaws.com/#{bucket}"
        when 'cdn'
          "language-archives.travis-ci.com/#{lang}"
        else
          "s3.amazonaws.com/#{bucket}" # explicitly state default
        end
      end

      def debug_build_via_api?
        ! data.debug_options.empty?
      end

      def config
        data.config
      end

      def app_host
        @app_host ||= Travis::Build.config.app_host.to_s.strip.output_safe
      end

      def debug_enabled?
        Travis::Build.config.enable_debug_tools == '1'
      end

      private

        def debug
          if debug_build_via_api?
            sh.echo "Debug build initiated by #{data.debug_options[:created_by]}", ansi: :yellow
            if debug_quiet?
              sh.raw "travis_debug --quiet"
            else
              sh.raw "travis_debug"
            end

            sh.newline
            sh.echo "All remaining steps, including caching and deploy, will be skipped.", ansi: :yellow
          end
        end

        def run
          stages.run if apply :validate
          sh.raw 'travis_cleanup'
          sh.raw 'travis_footer'
          # apply :deprecations
        end

        def header
          sh.raw '#!/bin/bash'
          sh.export 'TRAVIS_ROOT', root, echo: false, assert: false
          sh.export 'TRAVIS_HOME', home_dir, echo: false, assert: false
          sh.export 'TRAVIS_BUILD_DIR', build_dir, echo: false, assert: false
          sh.export 'TRAVIS_INTERNAL_RUBY_REGEX', internal_ruby_regex_esc,
                    echo: false, assert: false
          sh.export 'TRAVIS_APP_HOST', app_host,
                    echo: false, assert: false
          sh.export 'TRAVIS_APT_PROXY', apt_proxy,
                    echo: false, assert: false

          if Travis::Build.config.enable_infra_detection?
            sh.export 'TRAVIS_ENABLE_INFRA_DETECTION', 'true',
                      echo: false, assert: false
          end

          sh.raw bash('travis_preamble')
          sh.raw 'travis_preamble'

          sh.file '${TRAVIS_HOME}/.travis/functions',
                  "# travis_.+ functions:\n" +
                  TRAVIS_FUNCTIONS.map { |f| bash(f) }.join("\n")

          sh.file '${TRAVIS_HOME}/.travis/job_stages',
                  %[source "${TRAVIS_HOME}/.travis/functions"\n]
          sh.raw 'source "${TRAVIS_HOME}/.travis/functions"'
          sh.raw 'travis_setup_env'
          sh.raw 'travis_temporary_hacks'
        end

        def internal_ruby_regex_esc
          @internal_ruby_regex_esc ||= shesc(
            Travis::Build.config.internal_ruby_regex.output_safe
          )
        end

        def apt_proxy
          @apt_proxy ||= Travis::Build.config.apt_proxy.output_safe
        end

        def configure
          apply :check_unsupported
          apply :set_x
          apply :show_system_info
          apply :rm_riak_source
          apply :fix_rwky_redis
          apply :wait_for_network
          apply :update_apt_keys
          apply :fix_hhvm_source
          apply :update_mongo_arch
          apply :fix_container_based_trusty
          apply :fix_sudo_enabled_trusty
          apply :update_glibc
          apply :update_libssl
          apply :clean_up_path
          apply :fix_resolv_conf
          apply :fix_etc_hosts
          apply :fix_mvn_settings_xml
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
          apply :uninstall_oclint
          apply :rvm_use
          apply :rm_oraclejdk8_symlink
          apply :enable_i386
          apply :update_rubygems
          apply :ensure_path_components
          apply :redefine_curl
          apply :nonblock_pipe
          apply :apt_get_update
          apply :deprecate_xcode_64
          apply :update_heroku
          apply :shell_session_update
          apply :maven_central_mirror
          apply :maven_https

          check_deprecation
        end

        def setup_filter
          apply :no_world_writable_dirs
          apply :setup_filter
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

            sh.newline
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

        def error_message_ary(exception, event)
          if event
            contact_msg = ", or contact us at support@travis-ci.com"
            if event.id
              contact_msg << " with the error ID: #{event.id}"
            end
          else
            contact_msg = ""
          end

          if exception.is_a? Travis::Build::CompilationError
            msg = [
              exception.message
            ]
            doc_path = exception.doc_path
          else
            msg = [
              "Unfortunately, we do not know much about this error."
            ]
            doc_path = ''
          end

          [
            "",
            "There was an error in the .travis.yml file from which we could not recover.\n",
            *msg,
            "",
            "Please review https://docs.travis-ci.com#{doc_path}#{contact_msg}"
          ]
        end

        def show_compile_error_msg(exception, event)
          @sh = Shell::Builder.new
          error_message_ary(exception, event).each { |line| sh.raw "echo -e \"\033[31;1m#{line}\033[0m\"" }
          sh.raw "exit 2"
          Shell.generate(sh.to_sexp)
        end

        def lang_name
          self.class.name.split('::').last.downcase
        end

        def shesc(str)
          Shellwords.escape(str)
        end

        def check_deprecation
          return unless self.class.const_defined?("DEPRECATIONS")
          self.class.const_get("DEPRECATIONS").each do |cfg|
            if data.language_default_p && DateTime.now < Date.parse(cfg[:cutoff_date])
              sh.echo "Using the default #{cfg[:name] || self.class.name} version #{cfg[:current_default]}. " \
                "Starting on #{cfg[:cutoff_date]} the default will change to #{cfg[:new_default]}. " \
                "If you wish to keep using this version beyond this date, " \
                "please explicitly set the #{cfg[:name]} value in configuration.",
                ansi: :yellow
            end
          end
        end
    end
  end
end
