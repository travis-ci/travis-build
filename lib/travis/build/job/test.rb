require 'active_support/inflector/methods'

module Travis
  class Build
    module Job
      class Test
        autoload :Clojure, 'travis/build/job/test/clojure'
        autoload :Erlang,  'travis/build/job/test/erlang'
        autoload :Nodejs,  'travis/build/job/test/nodejs'
        autoload :Php,     'travis/build/job/test/php'
        autoload :Ruby,    'travis/build/job/test/ruby'

        extend Assertions

        class << self
          def by_lang(lang)
            lang = lang || 'ruby'
            args = [ActiveSupport::Inflector.camelize(lang.gsub('.', '').downcase)]
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

        def run
          { :status => perform ? 0 : 1 }
        end

        protected

          def perform
            chdir
            export
            checkout
            setup
            install
            run_scripts
          rescue AssertionFailed => e
            false
          end

          def chdir
            shell.chdir('~/builds')
          end

          def export
            Array(config.env).each do |env|
              shell.export(*env.split('=')) unless env.empty?
            end if config.env
          end

          def checkout
            commit.checkout
          end
          assert :checkout

          def setup
            # to be implemented in child classes
          end

          def install
            # to be implemented in child classes
          end

          def run_scripts
            %w{before_script script after_script}.each do |type|
              script = respond_to?(type, true) ? send(type) : config.send(type)
              return false if script && !run_script(script, :timeout => type.to_sym)
            end && true
          end

          def run_script(script, options = {})
            Array(script).each do |script|
              return false unless shell.execute(script, options)
            end && true
          end
      end
    end
  end
end
