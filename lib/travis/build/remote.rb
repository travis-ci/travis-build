module Travis
  class Build
    class Remote < Build
      attr_reader :name, :vm, :shell

      log_header { "#{Thread.current[:log_header]}:build:remote" }

      def initialize(vm, shell, events, job)
        super(events, job)
        @name = vm.name
        @vm = vm
        @shell = shell
      end

      def name
        vm.full_name
      end

      protected

        def perform
          log "Using worker: #{name}\n\n"
          result = vm.sandboxed do
            with_shell do
              job.run
            end
          end
          log "\nDone. Build script exited with: #{result[:status]}\n"
          result
        end

        def with_shell
          shell.connect
          shell.on_output(&method(:on_output))

          yield.tap do
            shell.close
          end
        end

        def on_output(output, options = {})
          log(output, options)
        end
    end
  end
end
