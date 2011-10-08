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

          def name
            # TODO where to obtain the host name?
            "ze monsta box: #{vm.name}"
          end

          protected

            def perform
              log "Using worker: #{name}\n\n"
              result = with_shell do
                vm.sandboxed do
                  job.run
                end
              end
              log "\nDone. Build script exited with: #{result}\n"
              result
            end

            def with_shell
              shell.connect
              shell.on_output(&method(:on_output))

              yield.tap do
                shell.close
              end
            end

            def on_output(output)
               log output
            end
        end
      end
    end
  end
end
