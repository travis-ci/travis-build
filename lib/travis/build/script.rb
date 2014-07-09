require 'core_ext/hash/deep_merge'
require 'core_ext/hash/deep_symbolize_keys'
require 'core_ext/object/false'
require 'erb'

module Travis
  module Build
    class Script
      autoload :Addons,         'travis/build/script/addons'
      autoload :Android,        'travis/build/script/android'
      autoload :C,              'travis/build/script/c'
      autoload :Cpp,            'travis/build/script/cpp'
      autoload :Clojure,        'travis/build/script/clojure'
      autoload :DirectoryCache, 'travis/build/script/directory_cache'
      autoload :Erlang,         'travis/build/script/erlang'
      autoload :Git,            'travis/build/script/git'
      autoload :Go,             'travis/build/script/go'
      autoload :Groovy,         'travis/build/script/groovy'
      autoload :Generic,        'travis/build/script/generic'
      autoload :Haskell,        'travis/build/script/haskell'
      autoload :Helpers,        'travis/build/script/helpers'
      autoload :Jdk,            'travis/build/script/jdk'
      autoload :Jvm,            'travis/build/script/jvm'
      autoload :NodeJs,         'travis/build/script/node_js'
      autoload :ObjectiveC,     'travis/build/script/objective_c'
      autoload :Perl,           'travis/build/script/perl'
      autoload :Php,            'travis/build/script/php'
      autoload :PureJava,       'travis/build/script/pure_java'
      autoload :Python,         'travis/build/script/python'
      autoload :Ruby,           'travis/build/script/ruby'
      autoload :Rust,           'travis/build/script/rust'
      autoload :RVM,            'travis/build/script/rvm'
      autoload :Scala,          'travis/build/script/scala'
      autoload :Services,       'travis/build/script/services'
      autoload :Stages,         'travis/build/script/stages'

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

      include Addons, Git, Helpers, Services, Stages, DirectoryCache

      attr_reader :stack, :data, :options

      def initialize(data, options = {})
        @data = Data.new({ config: self.class.defaults }.deep_merge(data.deep_symbolize_keys))
        @options = options
        @stack = [Shell::Script.new(echo: true, timing: true)]
      end

      def compile
        raw template 'header.sh'
        run_stages if check_config
        raw template 'footer.sh'
        sh.to_s
      end

      def cache_slug
        "cache"
      end

      private

        def check_config
          case data.config[:".result"]
          when 'not_found'
            echo 'Could not find .travis.yml, using standard configuration.', ansi: :red
            true
          when 'server_error'
            echo 'Could not fetch .travis.yml from GitHub.', ansi: :red
            raw 'travis_terminate 2'
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
        end

        def export
          set 'TRAVIS', 'true', echo: false
          set 'CI', 'true', echo: false
          set 'CONTINUOUS_INTEGRATION', 'true', echo: false
          set 'HAS_JOSH_K_SEAL_OF_APPROVAL', 'true', echo: false

          newline if data.env_vars_groups.any?(&:announce?)

          data.env_vars_groups.each do |group|
            echo "Setting environment variables from #{group.source}", ansi: :green if group.announce?
            group.vars.each { |var| set var.key, var.value, echo: var.to_s }
          end

          newline if data.env_vars_groups.any?(&:announce?)
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

        def template(filename)
          ERB.new(File.read(File.expand_path(filename, TEMPLATES_PATH))).result(binding)
        end

        def paranoid_mode
          if data.paranoid_mode?
            newline
            echo "Sudo, services, addons, setuid and setgid have been disabled.", ansi: :green
            newline
            raw 'sudo -n sh -c "sed -e \'s/^%.*//\' -i.bak /etc/sudoers && rm -f /etc/sudoers.d/travis && find / -perm -4000 -exec chmod a-s {} \; 2>/dev/null"'
          end
        end

        def setup_apt_cache
          if data.hosts && data.hosts[:apt_cache]
            echo 'Setting up APT cache', ansi: :green
            raw %(echo 'Acquire::http { Proxy "#{data.hosts[:apt_cache]}"; };' | sudo tee /etc/apt/apt.conf.d/01proxy &> /dev/null)
          end
        end

        def fix_resolv_conf
          return if data.skip_resolv_updates?
          raw %(grep '199.91.168' /etc/resolv.conf > /dev/null || echo 'nameserver 199.91.168.70\nnameserver 199.91.168.71' | sudo tee /etc/resolv.conf &> /dev/null)
        end

        def fix_etc_hosts
          return if data.skip_etc_hosts_fix?
          raw %(sudo sed -e 's/^\\(127\\.0\\.0\\.1.*\\)$/\\1 '`hostname`'/' -i'.bak' /etc/hosts)
          raw %(sudo bash -c 'echo "87.98.253.108 getcomposer.org" >> /etc/hosts')
        end

        def fix_ps4
          set "PS4", "+ ", echo: false
        end
    end
  end
end
