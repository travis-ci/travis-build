module Travis
  module Build
    class Script
      class Generic < Script
        DEFAULTS = {}

        def announce
          sh.cmd "bash --version", echo: true, assert: true, timing: false
        end
      end
    end
  end
end
