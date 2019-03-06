module Travis
  module Build
    class Script
      class Hack < Php
        DEFAULTS = {
          hhvm: 'hhvm' # lts
        }
        def configure
          super
        end

        def export
          super
        end

        def setup

        end

        def announce

        end

        def install

        end

        def script

        end

        def hhvm?
          unless config[:hhvm] =~ /^hhvm(?:-(dbg|dev|nightly|nightly-dbg|dev-nightly))?/
            sh.echo "hhvm version given #{config[:hhvm]}"
            sh.failure "hhvm version must be one of: hhvm, hhvm-dbg, hhvm-nightly, hhvm-nightly-dbg, hhmv-dev-nightly."
          end
        end
      end
    end
  end
end
