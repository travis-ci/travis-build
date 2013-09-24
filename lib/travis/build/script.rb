require 'core_ext/hash/deep_merge'
require 'core_ext/hash/deep_symbolize_keys'
require 'core_ext/object/false'
require 'erb'

module Travis
  module Build
    class Script
      autoload :Addons,         'travis/build/script/addons'
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
      autoload :RVM,            'travis/build/script/rvm'
      autoload :Scala,          'travis/build/script/scala'
      autoload :Services,       'travis/build/script/services'
      autoload :Stages,         'travis/build/script/stages'

      TEMPLATES_PATH = File.expand_path('../script/templates', __FILE__)

      STAGES = {
        builtin: [:export, :checkout, :setup, :announce],
        custom:  [:before_install, :install, :before_script, :script, :after_result, :after_script]
      }

      class << self
        def defaults
          Git::DEFAULTS.merge(self::DEFAULTS)
        end
      end

      include Addons, Git, Helpers, Services, Stages, DirectoryCache

      attr_reader :stack, :data, :options

      def initialize(data, options)
        @data = Data.new({ config: self.class.defaults }.deep_merge(data.deep_symbolize_keys))
        @options = options
        @stack = [Shell::Script.new(log: true, echo: true, log_file: logs[:build])]
      end

      def compile
        raw template 'header.sh'
        run_stages
        raw template 'footer.sh'
        sh.to_s
      end

      private

        def config
          data.config
        end

        def export
          data.env_vars.each do |var|
            set var.key, var.value, echo: var.to_s
          end
        end

        def finish
          push_directory_cache
        end

        def setup
          setup_directory_cache
          start_services
          setup_apt_cache if data.cache? :apt
          fix_resolv_conf
        end

        def announce
          # overwrite
        end

        def template(filename)
          ERB.new(File.read(File.expand_path(filename, TEMPLATES_PATH))).result(binding)
        end

        def logs
          @logs ||= LOGS.inject({}) do |logs, (type, log)|
            logs[type] = log if options[:logs][type] rescue nil
            logs
          end
        end

        def setup_apt_cache
          if data.hosts && data.hosts[:apt_cache]
            cmd 'echo -e "\033[33;1mSetting up APT cache\033[0m"', assert: false, echo: false
            cmd %Q{echo 'Acquire::http { Proxy "#{data.hosts[:apt_cache]}"; };' | sudo tee /etc/apt/apt.conf.d/01proxy  > /dev/null 2>&1}, echo: false, assert: false, log: false
          end
        end

        def fix_resolv_conf
          cmd %Q{echo 'nameserver 199.91.168.70\nnameserver 199.91.168.71' | sudo tee /etc/resolv.conf 2>&1 > /dev/null}, assert: false, echo: false, log: false
        end
    end
  end
end
