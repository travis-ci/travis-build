module Travis
  class Build
    class OutputLimitExceeded < StandardError
      def initialize(limit)
        super("The log length has exceeded the limit of #{limit} Bytes (this usually means that test suite is raising the same exception over and over). Terminating.")
      end
    end

    class CommandTimeout < StandardError
      def initialize(stage, command, timeout)
        super("Executing your #{stage} (#{command}) took longer than #{timeout/60} minutes and was terminated.\n\nFor more information about the test timeouts please checkout the section Build Timeouts at http://about.travis-ci.org/docs/user/build-configuration/.")
      end
    end
  end
end
