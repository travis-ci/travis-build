require "travis/build/length_limit"

module Travis
  class Build
    class Remote < Build
      # 2 MB per discussion with svenfuchs. MK.
      BUILD_LOG_LENGTH_LIMIT = 2 * 1024 * 1024

      attr_reader :name, :vm, :shell, :output_length

      log_header { "#{Thread.current[:log_header]}:build:remote" }

      def initialize(vm, shell, events, job)
        super(events, job)
        @name = vm.name
        @vm = vm
        @shell = shell

        @output_length_limit = LengthLimit.new(150)
        @injected_log_trimming_message = false
      end

      def injected_log_trimming_message?
        @injected_log_trimming_message
      end

      def drop_log_output?
        @output_length_limit.hit?
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

      def inject_log_limit_message!
        log("\n\n")
        log("[WARNING] Build log length has exceeded the limit (2 MB). This usually means that test suite is raising the same exception over and over. Ignoring all subsequent output.")
        log("\n\n")

        @injected_log_trimming_message = true
      end

      def maybe_log(output, options = {})
        if drop_log_output?
          inject_log_limit_message! unless injected_log_trimming_message?
        else
          log(output, options)
        end

        @output_length_limit.update(output)
      end

      def on_output(output, options = {})
        maybe_log(output, options)
      end
    end
  end
end
