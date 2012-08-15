require 'active_support/inflector/methods'
require 'active_support/core_ext/object/blank'
require 'timeout'

module Travis
  class Build
    module Job

      # Job::Test subclasses execute test suite run using presets for the given
      # language.
      #
      # A test job takes
      #  * a shell (ssh shell into a running vm) which will be used to run comands
      #  * a commit which can be checked out from Github
      #  * the configuration for this test run
      #
      # A test job performs the following steps:
      #
      #  * change to the vm's build working directory
      #  * export enviroment variables as defined by the configuration as well
      #    as variables that inform about the current environment
      #  * check out the commit from Github
      #  * setup the build if required for the current language (e.g. switch to
      #    the given Ruby version and define the Gemfile for bundler if used)
      #  * run the before_install, install, before_script, script, and
      #    after_script commands
      #
      # The install and script commands might be defined by the language
      # specific test subclasses. All of the commands can be defined in the
      # test configuration.
      class Test
        autoload :C,           'travis/build/job/test/c'
        autoload :Clojure,     'travis/build/job/test/clojure'
        autoload :Cpp,         'travis/build/job/test/cpp'
        autoload :Erlang,      'travis/build/job/test/erlang'
        autoload :Go,          'travis/build/job/test/go'
        autoload :Groovy,      'travis/build/job/test/groovy'
        autoload :Haskell,     'travis/build/job/test/haskell'
        autoload :JdkSwitcher, 'travis/build/job/test/jdk_switcher'
        autoload :JvmLanguage, 'travis/build/job/test/jvm_language'
        autoload :NodeJs,      'travis/build/job/test/node_js'
        autoload :Perl,        'travis/build/job/test/perl'
        autoload :Php,         'travis/build/job/test/php'
        autoload :PureJava,    'travis/build/job/test/pure_java'
        autoload :Python,      'travis/build/job/test/python'
        autoload :Ruby,        'travis/build/job/test/ruby'
        autoload :Scala,       'travis/build/job/test/scala'

        STAGES = [:before_install, :install, :before_script, :script, :after_script]

        extend Assertions
        include Logging

        log_header { "#{Thread.current[:log_header]}:job:test" }

        class << self
          def by_lang(lng)
            lang = (Array(lng).first || 'ruby').downcase.strip

            case lang
            when /^java/i then
              # just "Java" would conflict with JRuby's Java integration
              Job::Test::PureJava
            when "c++", "cpp", "cplusplus" then
              Job::Test::Cpp
            else
              args = [ActiveSupport::Inflector.camelize(lang.downcase)]
              args << false if Kernel.method(:const_get).arity == -1
              Job::Test.const_get(*args) rescue Job::Test::Ruby
            end
          end
        end

        attr_reader :shell, :commit, :config, :repository

        def initialize(shell, commit, config)
          @shell = shell
          @commit = commit
          @config = config

          @repository = @commit.repository
        end

        def install
          # intentional no-op. We need to overwrite Kernel#install which is added by Rake
          # because we use `respond_to?` in `commands_for`.
        end

        def run
          { :result => perform ? 0 : 1 }
        end
        log :run

        protected

        def perform
          chdir
          export
          checkout
          setup if respond_to?(:setup)
          run_stages
        rescue CommandTimeout, OutputLimitExceeded => e
          shell.echo "\n\n#{e.message}\n\n", :force => true
          false
        rescue AssertionFailed => e
          log_exception(e)
          false
        end

        def chdir
          shell.chdir('~/builds')
        end

        def export
          export_travis_specific_variables

          env_vars.each do |line|
            shell.export_line(line)
          end
        end

        def export_travis_specific_variables
          shell.export_line "TRAVIS_PULL_REQUEST=#{(!!commit.pull_request?).inspect}"
          shell.export_line "TRAVIS_SECURE_ENV_VARS=#{secure_env_vars?}"
          if commit.pull_request?
            shell.export_line "TRAVIS_PULL_REQUEST_NUMBER=#{commit.pull_request_number}"
          end
        end

        def env_vars
          if config.env
            Array(config.env).compact.select { |line| line.present? }
          else
            []
          end
        end

        def secure_env_vars?
          !commit.pull_request? && env_vars.any? { |line| line =~ /^SECURE / }
        end

        def checkout
          commit.checkout
        end
        assert :checkout

        def setup
          export_environment_variables
        end

        # Exports system env variables like TRAVIS_RUBY_VERSION, TRAVIS_SCALA_VERSION and so on.
        def export_environment_variables
          # no-op, overriden by subclasses. MK.
        end

        def home_directory
          "/home/vagrant"
        end

        def run_stages
          STAGES.each do |stage|
            return false unless run_commands(stage)
          end && true
        end

        def run_commands(stage)
          commands_for(stage).each do |command|
            return false unless run_command(stage, command)
          end && true
        end

        def run_command(stage, command)
          result = shell.execute(command, :stage => stage)
          shell.echo "\n\n#{stage}: '#{command}' returned false." if !result && stage != :script
          result
        end

        def commands_for(stage)
          Array(config[stage] || (respond_to?(stage, true) ? send(stage) : nil))
        end


        def source_url
          repository.source_url
        end

        def repository_slug
          repository.slug
        end

        def repository_owner
          repository.slug.split("/").first
        end

        def repository_name
          repository.slug.split("/").last
        end
      end
    end
  end
end
