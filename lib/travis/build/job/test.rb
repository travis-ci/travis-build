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
        autoload :Clojure,     'travis/build/job/test/clojure'
        autoload :Erlang,      'travis/build/job/test/erlang'
        autoload :Groovy,      'travis/build/job/test/groovy'
        autoload :PureJava,    'travis/build/job/test/pure_java'
        autoload :JvmLanguage, 'travis/build/job/test/jvm_language'
        autoload :NodeJs,      'travis/build/job/test/node_js'
        autoload :Perl,        'travis/build/job/test/perl'
        autoload :Php,         'travis/build/job/test/php'
        autoload :Python,      'travis/build/job/test/python'
        autoload :Ruby,        'travis/build/job/test/ruby'
        autoload :Scala,       'travis/build/job/test/scala'

        STAGES = [:before_install, :install, :before_script, :script, :after_script]

        extend Assertions
        include Logging

        log_header { "#{Thread.current[:log_header]}:job:test" }

        class << self
          def by_lang(lang)
            lang = Array(lang).first
            lang = (lang || 'ruby').downcase

            if lang == 'java'
              Job::Test::PureJava
            else
              args = [ActiveSupport::Inflector.camelize(lang.downcase)]
              args << false if Kernel.method(:const_get).arity == -1
              Job::Test.const_get(*args) rescue Job::Test::Ruby
            end
          end
        end

        attr_reader :shell, :commit, :config

        def initialize(shell, commit, config)
          @shell = shell
          @commit = commit
          @config = config
        end

        def install
          # intentional no-op. We need to overwrite Kernel#install which is added by Rake
          # because we use `respond_to?` in `commands_for`.
        end

        def run
          { :status => perform ? 0 : 1 }
        end
        log :run

        protected

          def perform
            chdir
            export
            checkout
            setup if respond_to?(:setup)
            run_stages
          rescue AssertionFailed => e
            log_exception(e)
            false
          end

          def chdir
            shell.chdir('~/builds')
          end

          def export
            Array(config.env).compact.select { |line| line.present? }.each do |line|
              shell.export_line(line)
            end if config.env
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
            unless shell.execute(command, :timeout => stage)
              shell.echo "\n\n#{stage}: '#{command}' returned false." unless stage == :script
              false
            else
              true
            end
          rescue Timeout::Error => e
            timeout = shell.timeout(stage)
            shell.echo "\n\n#{stage}: Execution of '#{command}' took longer than #{timeout} seconds and was terminated. Consider rewriting your stuff in AssemblyScript, we've heard it handles Web Scale\342\204\242\n\n"
            false
          end

          def commands_for(stage)
            Array(config[stage] || (respond_to?(stage, true) ? send(stage) : nil))
          end
      end
    end
  end
end
