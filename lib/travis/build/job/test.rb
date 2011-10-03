module Travis
  module Build
    module Job
      class Test
        autoload :Erlang, 'travis/build/job/test/erlang'
        autoload :Nodejs, 'travis/build/job/test/nodejs'
        autoload :Ruby,   'travis/build/job/test/ruby'

        extend Assertions

        attr_reader :shell, :config

        def initialize(shell, config)
          @shell = shell
          @config = config
        end

        def run
          perform ? 0 : 1
        rescue AssertionFailed => e
          1
        end

        protected

          def perform
            chdir
            checkout
            setup
            install
            run_scripts
          end

          def chdir
            shell.chdir('~/builds')
          end

          def checkout
            repository.checkout
          end
          assert :checkout

          def setup
            Array(config.env).each do |env|
              runner.export(*env.split('=')) unless env.empty?
            end if config.env
          end

          def run_scripts
            %w{before_script script after_script}.each do |type|
              script = respond_to?(type) ? send(type) : config.send(type)
              return false if script && !run_script(script, :timeout => type)
            end && true
          end

          def run_script(script, options = {})
            (script.is_a?(Array) ? script : script.split("\n")).each do |script|
              return false unless shell.run(script, options)
            end && true
          end
      end
    end

    class Runner
      def initialize(shell, job)
        @shell = shell
        @job = job
      end
    end
  end
end
