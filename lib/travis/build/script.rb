require 'core_ext/hash/deep_merge'
require 'core_ext/hash/deep_symbolize_keys'
require 'core_ext/object/false'
require 'erb'
require 'ostruct'

module Travis
  module Build
    class Script
      autoload :Addons,         'travis/build/script/addons'
      autoload :Deprecation,    'travis/build/script/deprecation'
      autoload :DirectoryCache, 'travis/build/script/directory_cache'
      autoload :Services,       'travis/build/script/services'
      autoload :Stages,         'travis/build/script/stages'
      autoload :Templates,      'travis/build/script/templates'

      autoload :Android,        'travis/build/script/lang/android'
      autoload :C,              'travis/build/script/lang/c'
      autoload :Cpp,            'travis/build/script/lang/cpp'
      autoload :Clojure,        'travis/build/script/lang/clojure'
      autoload :Erlang,         'travis/build/script/lang/erlang'
      autoload :Go,             'travis/build/script/lang/go'
      autoload :Groovy,         'travis/build/script/lang/groovy'
      autoload :Generic,        'travis/build/script/lang/generic'
      autoload :Haskell,        'travis/build/script/lang/haskell'
      autoload :NodeJs,         'travis/build/script/lang/node_js'
      autoload :ObjectiveC,     'travis/build/script/lang/objective_c'
      autoload :Perl,           'travis/build/script/lang/perl'
      autoload :Php,            'travis/build/script/lang/php'
      autoload :PureJava,       'travis/build/script/lang/pure_java'
      autoload :Python,         'travis/build/script/lang/python'
      autoload :Ruby,           'travis/build/script/lang/ruby'
      autoload :Rust,           'travis/build/script/lang/rust'
      autoload :Scala,          'travis/build/script/lang/scala'

      autoload :Bundler,        'travis/build/script/shared/bundler'
      autoload :Git,            'travis/build/script/shared/git'
      autoload :Jdk,            'travis/build/script/shared/jdk'
      autoload :Jvm,            'travis/build/script/shared/jvm'
      autoload :RVM,            'travis/build/script/shared/rvm'


      TEMPLATES_PATH = File.expand_path('../script/templates', __FILE__)

      STAGES = {
        builtin: [:configure, :checkout, :pre_setup, :paranoid_mode, :export, :setup, :announce],
        custom:  [:before_install, :install, :before_script, :script, :after_result, :after_script]
      }

      class << self
        def defaults
          Git::DEFAULTS.merge(self::DEFAULTS)
        end
      end

      include Addons, Git, Services, Stages, DirectoryCache, Deprecation, Templates

      attr_reader :sh, :data, :options

      def initialize(data, options = {})
        @data = Data.new({ config: self.class.defaults }.deep_merge(data.deep_symbolize_keys))
        @options = options
        @sh = Shell::Builder.new
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

        def run
          run_stages if check_config
          sh.raw template('footer.sh')
          notify_deprecations
          sh.raw template('header.sh'), pos: 0
        end

        def check_config
          case data.config[:".result"]
          when 'not_found'
            sh.echo 'Could not find .travis.yml, using standard configuration.', ansi: :red
            true
          when 'server_error'
            sh.echo 'Could not fetch .travis.yml from GitHub.', ansi: :red
            sh.raw 'travis_terminate 2'
            false
          else
            true
          end
        end

        def config
          data.config
        end

        def configure
          fix_resolv_conf
          fix_etc_hosts
          run_addons(:before_checkout)
        end

        def export
          sh.export 'TRAVIS', 'true', echo: false
          sh.export 'CI', 'true', echo: false
          sh.export 'CONTINUOUS_INTEGRATION', 'true', echo: false
          sh.export 'HAS_JOSH_K_SEAL_OF_APPROVAL', 'true', echo: false

          sh.newline if data.env_vars_groups.any?(&:announce?)

          data.env_vars_groups.each do |group|
            sh.echo "Setting environment variables from #{group.source}", ansi: :yellow if group.announce?
            group.vars.each { |var| sh.export(var.key, var.value, echo: var.echo?, secure: var.secure?) }
          end

          sh.newline if data.env_vars_groups.any?(&:announce?)
        end

        def pre_setup
          start_services
          setup_apt_cache if data.cache? :apt
          fix_ps4
          run_addons(:after_pre_setup)
        end

        def setup
        end

        def announce
        end

        def finish
        end

        def paranoid_mode
          if data.paranoid_mode?
            sh.newline
            sh.echo "Sudo, the FireFox addon, setuid and setgid have been disabled.", ansi: :yellow
            sh.newline
            sh.cmd 'sudo -n sh -c "sed -e \'s/^%.*//\' -i.bak /etc/sudoers && rm -f /etc/sudoers.d/travis && find / -perm -4000 -exec chmod a-s {} \; 2>/dev/null"'
          end
        end

        def setup_apt_cache
          if data.hosts && data.hosts[:apt_cache]
            sh.echo 'Setting up APT cache', ansi: :yellow
            sh.cmd %(echo 'Acquire::http { Proxy "#{data.hosts[:apt_cache]}"; };' | sudo tee /etc/apt/apt.conf.d/01proxy &> /dev/null)
          end
        end

        def fix_resolv_conf
          return if data.skip_resolv_updates?
          sh.cmd %(grep '199.91.168' /etc/resolv.conf > /dev/null || echo 'nameserver 199.91.168.70\nnameserver 199.91.168.71' | sudo tee /etc/resolv.conf &> /dev/null)
        end

        def fix_etc_hosts
          return if data.skip_etc_hosts_fix?
          sh.cmd %(sudo sed -e 's/^\\(127\\.0\\.0\\.1.*\\)$/\\1 '`hostname`'/' -i'.bak' /etc/hosts)
        end

        def fix_ps4
          sh.export "PS4", "+ ", echo: false
        end

        def notify_deprecations
          deprecations.map.with_index do |msg, ix|
            sh.fold "deprecated.#{ix}", pos: ix do
              sh.deprecate "DEPRECATED: #{unindent(msg)}"
            end
          end
        end

        def unindent(str)
          str.gsub /^#{str[/\A\s*/]}/, ''
        end
    end
  end
end
