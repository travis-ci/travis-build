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
      #  * run the before_install, install, before_script, abd script commands
      #  * run after_success, after_failure and after_script commands
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

        STAGES = [:before_install, :install, :before_script, :script]

        extend Assertions
        include Logging

        log_header { [Thread.current[:log_header], "build:job:test"].join(':') }

        class << self
          def by_lang(lng)
            lang = (Array(lng).first || 'ruby').to_s.downcase.strip

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
          state = self.perform

          # here we have the final success/failure flag so we can take care of after_success, after_failure. MK.
          if state == :passed
            run_after_success if commands_for(:after_success).any?
          elsif state == :failed
            run_after_failure if commands_for(:after_failure).any?
          end

          code = { :passed => 0, :failed => 1 }[state]
          run_after_script(code) if code

          { :state => state }
        end
        log :run

        protected

        def perform
          chdir
          export
          start_services
          checkout
          setup if respond_to?(:setup)
          run_stages ? :passed : :failed
        rescue CommandTimeout, OutputLimitExceeded => e
          shell.echo "\n\n#{e.message}\n\n", :force => true
          :errored
        rescue AssertionFailed => e
          log_exception(e)
          :errored
        end
        log :perform

        def start_services
          xs = Array(config.services || []).
            map { |s| normalize_service(s) }

          if xs.any?
            xs.each { |s| start_service(s) }
            # give services a moment to start
            shell.execute "sleep 3"
          end
        end

        def normalize_service(name)
          s = name.to_s.downcase
          case s
          when "rabbitmq" then
            "rabbitmq-server"
          when "memcache" then
            "memcached"
          when "neo4j", "neo4j-server" then
            "neo4j"
          # for HBase status, see travis-ci/travis-cookbooks#40. MK.
          when "hbase" then
            "hbase-master"
          when "redis" then
            "redis-server"
          else
            s
          end
        end

        def start_service(name)
          shell.execute "sudo service #{name} start", :stage => :services
        end

        def chdir
          shell.chdir("~/builds")
        end
        log :chdir, :only => :before

        def export
          export_travis_specific_variables

          env_vars.each do |line|
            shell.export_line(line)
          end
        end
        log :export, :only => :before

        def export_travis_specific_variables
          shell.export_line "TRAVIS_PULL_REQUEST=#{commit.pull_request}"
          shell.export_line "TRAVIS_SECURE_ENV_VARS=#{secure_env_vars?}"
          shell.export_line "TRAVIS_JOB_ID=#{commit.job_id}"
          shell.export_line "TRAVIS_BRANCH=#{commit.job.branch}"
          shell.export_line "TRAVIS_BUILD_ID=#{commit.build.id}"
          shell.export_line "TRAVIS_BUILD_NUMBER=#{commit.build.number}"
          shell.export_line "TRAVIS_JOB_NUMBER=#{commit.job.number}"
          shell.export_line "TRAVIS_COMMIT_RANGE=#{commit.job.commit_range}"
          shell.export_line "TRAVIS_COMMIT=#{commit.job.commit}"
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
        log :checkout, :only => :before

        def setup
          export_environment_variables
        end
        log :setup, :only => :before

        # Exports system env variables like TRAVIS_RUBY_VERSION, TRAVIS_SCALA_VERSION and so on.
        def export_environment_variables
          # no-op, overriden by subclasses. MK.
        end

        def home_directory
          "~"
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
        log :run_command, :only => :before

        def commands_for(stage)
          Array(config[stage] || (respond_to?(stage, true) ? send(stage) : nil))
        end

        def run_after_success
          Array(config.after_success || []).each do |command|
            # we don't check for exit code here since this runs after the build has finished. MK.
            shell.execute(command, :stage => :after_success)
          end
        end
        log :run_after_success, :only => :before

        def run_after_failure
          Array(config.after_failure || []).each do |command|
            # we don't check for exit code here since this runs after the build has finished. MK.
            shell.execute(command, :stage => :after_failure)
          end
        end
        log :run_after_failure, :only => :before

        def run_after_script(code)
          retries = 0
          after_script_lines = Array(config.after_script || [])

          return if after_script_lines.empty?

          begin
            shell.export_line "TRAVIS_TEST_RESULT=#{code}"
          rescue Travis::Build::CommandTimeout
            raise if retries > 2
            retries += 1
            sleep 1 + retries
            retry
          end

          after_script_lines.each do |command|
            shell.execute(command, :stage => :after_script)
          end
        end
        log :run_after_script, :only => :before

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
