require 'active_support/inflector/methods'

# # rake and fileutils might be mixed into the global namespace, defining :install
# class Hashr; undef :install; end

module Travis
  class Build
    module Job
      class Test
        autoload :Clojure, 'travis/build/job/test/clojure'
        autoload :Erlang,  'travis/build/job/test/erlang'
        autoload :NodeJs,  'travis/build/job/test/node_js'
        autoload :Php,     'travis/build/job/test/php'
        autoload :Ruby,    'travis/build/job/test/ruby'

        COMMANDS = %w(before_install install before_script script after_script)

        extend Assertions
        include Logging

        log_header { "#{Thread.current[:log_header]}:job:test" }

        class << self
          def by_lang(lang)
            lang = lang || 'ruby'
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
            Array(config.env).each do |list|
              list.split(" ").each do |env|
                shell.export(*env.split('=')) unless env.empty?
              end
            end if config.env
          end

          def checkout
            commit.checkout
          end
          assert :checkout

          def run_commands
            COMMANDS.each do |type|
              next unless command = self.command(type)
              if command && !run_command(command, :timeout => type.to_sym)
                shell.echo "#{type}: #{command} returned false." unless type == 'script'
                return false
              end
            end && true
          end

          def run_command(script, options = {})
            Array(script).each do |script|
              return false unless shell.execute(script, options)
            end && true
          end

          def command(type)
            config[type] || (respond_to?(type, true) ? send(type) : nil)
          end
      end
    end
  end
end
