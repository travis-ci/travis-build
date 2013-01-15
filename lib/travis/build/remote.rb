module Travis
  class Build

    # Build that runs the given job in the given vm through the given shell.
    class Remote < Build
      attr_reader :name, :vm, :shell, :output_length

      log_header { [Thread.current[:log_header], "build:remote"].join(':') }

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
          log "\nDone. Build script exited with: #{{ :passed => 0, :failed => 1 }[result[:state]]}\n"
          result
        end

        def with_shell
          shell.connect
          shell.on_output(&method(:log))
          yield
        ensure
          shell.close
        end

        def notify(type, data)
          data.merge!(:worker => name) if type == :start
          super
        end
    end
  end
end
