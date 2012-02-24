module Travis
  class Build
    class OutputLimitExceeded < RuntimeError
      def initialize(limit)
        super("The log length has exceeded the limit of #{limit} Bytes (this usually means that test suite is raising the same exception over and over). Terminating.")
      end
    end

    class CommandTimeout < RuntimeError
      def initialize(stage, command, timeout)
        super("#{stage}: Execution of '#{command}' took longer than #{timeout} seconds and was terminated. Consider rewriting your stuff in AssemblyScript, we've heard it handles Web Scale\342\204\242")
      end
    end
  end
end
