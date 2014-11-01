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
      autoload :DirectoryCache, 'travis/build/script/shared/directory_cache'
      autoload :Env,            'travis/build/script/shared/env'
      autoload :Git,            'travis/build/script/shared/git'
      autoload :Jdk,            'travis/build/script/shared/jdk'
      autoload :Jvm,            'travis/build/script/shared/jvm'
      autoload :RVM,            'travis/build/script/shared/rvm'


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
      include Git, Services, DirectoryCache, Deprecation, Templates

      attr_reader :sh, :data, :options, :addons, :stages

      def initialize(data, options = {})
        @data = Data.new({ config: self.class.defaults }.deep_merge(data.deep_symbolize_keys))
        @options = options
        @sh = Shell::Builder.new
        @addons = Addons.new(sh, self.data, config)
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
          stages.run if validate
          sh.raw template('footer.sh')
          notify_deprecations
          sh.raw template('header.sh'), pos: 0
        end

        def validate
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

        def configure
          fix_resolv_conf
          fix_etc_hosts
          run_addons(:before_checkout)
        end

        def export
          Env.new(sh, data).export
        end

        def prepare
          start_services
          setup_apt_cache if data.cache? :apt
          fix_ps4
          paranoid_mode if paranoid_mode?
        end

        def paranoid_mode?
          data.paranoid_mode?
        end

        def paranoid_mode
          sh.newline
          sh.echo "Sudo, the FireFox addon, setuid and setgid have been disabled.", ansi: :yellow
          sh.newline
          sh.cmd 'sudo -n sh -c "sed -e \'s/^%.*//\' -i.bak /etc/sudoers && rm -f /etc/sudoers.d/travis && find / -perm -4000 -exec chmod a-s {} \; 2>/dev/null"'
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
              sh.deprecate "DEPRECATED: #{msg.gsub /^#{msg[/\A\s*/]}/, ''}"
            end
          end
        end
    end
  end
end
