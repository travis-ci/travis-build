module Travis
  module Build
    module Job
      class Runner
        class Remote < Runner
          attr_reader :vm, :shell

          def initialize(vm, shell, job)
            super(job)
            @vm = vm
            @shell = shell
          end

          protected

            def perform
              with_shell do
                vm.sandboxed do
                  job.run
                end
              end
            end

            def with_shell
              shell.connect
              shell.on_output(&method(:on_output))

              yield.tap do
                shell.close
              end
            end

            def on_output(output)
               log(job, output)
            end
        end
      end
    end
  end
end
