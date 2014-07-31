require 'erb'
require 'core_ext/hash/deep_merge'
require 'core_ext/hash/deep_symbolize_keys'
require 'core_ext/object/false'

module Travis
  module Build
    class Script
      autoload :Addons,         'travis/build/script/addons'
      autoload :Android,        'travis/build/script/langs/android'
      autoload :C,              'travis/build/script/langs/c'
      autoload :Cpp,            'travis/build/script/langs/cpp'
      autoload :Clojure,        'travis/build/script/langs/clojure'
      autoload :Erlang,         'travis/build/script/langs/erlang'
      autoload :Go,             'travis/build/script/langs/go'
      autoload :Groovy,         'travis/build/script/langs/groovy'
      autoload :Haskell,        'travis/build/script/langs/haskell'
      autoload :Helpers,        'travis/build/script/helpers'
      autoload :NodeJs,         'travis/build/script/langs/node_js'
      autoload :ObjectiveC,     'travis/build/script/langs/objective_c'
      autoload :Perl,           'travis/build/script/langs/perl'
      autoload :Php,            'travis/build/script/langs/php'
      autoload :PureJava,       'travis/build/script/langs/pure_java'
      autoload :Python,         'travis/build/script/langs/python'
      autoload :Ruby,           'travis/build/script/langs/ruby'
      autoload :Scala,          'travis/build/script/langs/scala'
      autoload :DirectoryCache, 'travis/build/script/shared/directory_cache'
      autoload :Git,            'travis/build/script/shared/git'
      autoload :Jdk,            'travis/build/script/shared/jdk'
      autoload :Jvm,            'travis/build/script/shared/jvm'
      autoload :RVM,            'travis/build/script/shared/rvm'
      autoload :Services,       'travis/build/script/services'
      autoload :Stages,         'travis/build/script/stages'

      TEMPLATES_PATH = File.expand_path('templates', __FILE__.gsub('.rb', ''))

      STAGES = {
        builtin: [:configure, :checkout, :pre_setup, :paranoid_mode, :export, :setup, :announce],
        custom:  [:before_install, :install, :before_script, :script, :after_result, :after_script]
      }

      class << self
        def defaults
          Git::DEFAULTS.merge(self::DEFAULTS)
        end
      end

      include Addons, Git, Helpers, Services, Stages, DirectoryCache

      attr_reader :sh, :data

      def initialize(data)
        @sh = Shell::Builder.new
        @data = Data.new({ config: self.class.defaults }.deep_merge(data.deep_symbolize_keys))
        run
      end

      def compile
        Shell.generate(sexp)
      end

      def sexp
        sh.to_sexp
      end

      def cache_slug
        "cache"
      end

      private

        def run
          sh.raw [template('header.sh')]
          run_stages if check_config
          sh.raw template('footer.sh')
        end

        def check_config
          case data.config[:".result"]
          when 'not_found'
            sh.echo 'Could not find .travis.yml, using standard configuration.', ansi: :red
            true
          when 'server_error'
            sh.echo 'Could not fetch .travis.yml from GitHub.', ansi: :red
            sh.cmd 'travis_terminate 2', timing: false
            false
          else
            true
          end
        end

        def config
          data.config
        end

        def configure
          fix_resolv_conf unless data.skip_resolv_updates?
          fix_etc_hosts   unless data.skip_etc_hosts_fix?
        end

        def export
          sh.export 'TRAVIS', 'true', echo: false
          sh.export 'CI', 'true', echo: false
          sh.export 'CONTINUOUS_INTEGRATION', 'true', echo: false
          sh.export 'HAS_JOSH_K_SEAL_OF_APPROVAL', 'true', echo: false

          sh.newline if data.env_vars_groups.any?(&:announce?)

          data.env_vars_groups.each do |group|
            sh.echo "Setting environment variables from #{group.source}", ansi: :green if group.announce?
            group.vars.each { |var| sh.export var.key, var.value, echo: var.echo?, secure: var.secure? }
          end

          sh.newline if data.env_vars_groups.any?(&:announce?)
        end

        def finish
          push_directory_cache
        end

        def pre_setup
          start_services
          setup_apt_cache if data.cache? :apt
          fix_ps4
          run_addons(:after_pre_setup)
        end

        def setup
          setup_directory_cache
        end

        def announce
          # overwrite
        end

        def paranoid_mode
          if data.paranoid_mode?
            sh.newline
            sh.echo "Sudo, services, addons, setuid and setgid have been disabled.", ansi: :green
            sh.newline
            sh.cmd 'sudo -n sh -c "sed -e \'s/^%.*//\' -i.bak /etc/sudoers && rm -f /etc/sudoers.d/travis && find / -perm -4000 -exec chmod a-s {} \; 2>/dev/null"', timing: false
          end
        end

        def setup_apt_cache
          if data.hosts && data.hosts[:apt_cache]
            sh.echo 'Setting up APT cache', ansi: :green
            sh.cmd %(echo 'Acquire::http { Proxy "#{data.hosts[:apt_cache]}"; };' | sudo tee /etc/apt/apt.conf.d/01proxy &> /dev/null), timing: false
          end
        end

        def fix_resolv_conf
          sh.cmd %(grep '199.91.168' /etc/resolv.conf > /dev/null || echo 'nameserver 199.91.168.70\nnameserver 199.91.168.71' | sudo tee /etc/resolv.conf &> /dev/null), timing: false
        end

        def fix_etc_hosts
          sh.cmd %(sudo sed -e 's/^\\(127\\.0\\.0\\.1.*\\)$/\\1 '`hostname`'/' -i'.bak' /etc/hosts), timing: false
          sh.cmd %(sudo bash -c 'echo "87.98.253.108 getcomposer.org" >> /etc/hosts'), timing: false
        end

        def fix_ps4
          sh.export "PS4", "+ "
        end
    end
  end
end
