require 'active_support/inflector/methods'
require 'active_support/core_ext/object/blank'
require 'timeout'

# # rake and fileutils might be mixed into the global namespace, defining :install
# class Hashr; undef :install; end

module Travis
  class Build
    module Job
      class Test
        autoload :Clojure,     'travis/build/job/test/clojure'
        autoload :Erlang,      'travis/build/job/test/erlang'
        autoload :Groovy,      'travis/build/job/test/groovy'
        autoload :PureJava,    'travis/build/job/test/pure_java'
        autoload :JvmLanguage, 'travis/build/job/test/jvm_language'
        autoload :NodeJs,      'travis/build/job/test/node_js'
        autoload :Php,         'travis/build/job/test/php'
        autoload :Ruby,        'travis/build/job/test/ruby'
        autoload :Scala,       'travis/build/job/test/scala'
        autoload :Perl,        'travis/build/job/test/perl'

        COMMANDS = %w(before_install install before_script script after_script)

        extend Assertions
        include Logging

        log_header { "#{Thread.current[:log_header]}:job:test" }

        class << self
          def by_lang(lang)
            lang = Array(lang).first
            lang = (lang || 'ruby').downcase
            # Java builder cannot follow typical conventions
            # because JRuby won't let us use a class named "Java". MK.
            return Job::Test::PureJava if lang == "java"

            args = [ActiveSupport::Inflector.camelize(lang.downcase)]
            args << false if Kernel.method(:const_get).arity == -1
            Job::Test.const_get(*args) rescue Job::Test::Ruby
          end
        end

        attr_reader :shell, :commit, :config

        def initialize(shell, commit, config)
          @shell = shell
          @commit = commit
          @config = config
        end

        def setup
          export_environment_variables
        end

        def install
          # intentional no-op. If we don't define this method, builders
          # that do not define #install (like the php one) will fail because
          # rake defines Kernel#install with different arity. Because we cannot
          # guarantee that all of our dependencies will correctly depend on rake only
          # for development and occasionally people may forget to run
          # bundle install --without test. So, the best solution may be to just difine this no-op
          # method. MK.
        end

        def run
          { :status => perform ? 0 : 1 }
        end
        log :run

        protected

        def export_environment_variables
          # no-op, overriden by subclasses. MK.
        end

          def perform
            chdir
            export
            checkout
            setup if respond_to?(:setup)
            run_commands
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

          def run_commands
            COMMANDS.each do |category|
              return false unless run_commands_for_category(category)
            end && true
          end

          def run_commands_for_category(category)
            commands(category).each do |command|
              return false unless run_command(command, :category => category.to_sym)
            end && true
          end

          def run_command(command, options = {})
            category = options[:category]
            unless shell.execute(command, :timeout => category)
              shell.echo "\n\n#{category}: '#{command}' returned false." unless category == :script
              false
            else
              true
            end
          rescue Timeout::Error => e
            timeout  = shell.timeout(category)
            shell.echo "\n\n#{category}: Execution of '#{command}' took longer than #{timeout} seconds and was terminated. Consider rewriting your stuff in AssemblyScript, we've heard it handles Web Scale\342\204\242\n\n"
            false
          end

          def commands(type)
            commands = config[type] || (respond_to?(type, true) ? send(type) : nil)
            Array(commands)
          end
      end
    end
  end
end
