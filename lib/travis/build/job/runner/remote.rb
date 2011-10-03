module Travis
  module Build
    module Job
      class Runner
        class Remote < Runner
          attr_reader :vm, :shell

          def initialize(job, vm)
            super(job)
            @vm = vm
            @shell = vm.shell
          end

          protected

            def perform
              vm.sandboxed do
                with_shell do
                  job.run
                end
              end
            end

            def with_shell
              shell.connect
              shell.on_output { |output| log(job, output) }

              yield.tap do
                shell.close
              end
            end
        end
      end
    end
  end
