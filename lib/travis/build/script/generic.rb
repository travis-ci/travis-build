module Travis
  module Build
    class Script
      class Generic < Script
        DEFAULTS = {}

        def announce
          sh.cmd "bash -c 'echo $BASH_VERSION'", echo: true, assert: true, timing: false
          sh.newline
        end
      end
    end
  end
end
