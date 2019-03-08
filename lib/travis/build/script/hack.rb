module Travis
  module Build
    class Script
      class Hack < Php
        DEFAULTS = {
          hhvm: 'hhvm',
          php: '7.2',
        }

        VALID_HHVM = %w(
          hhvm
          hhvm-dbg
          hhvm-nightly
          hhvm-nightly-dbg
          hhvm-dev-nightly
        )

        def configure
          super
        end

        def export
          super
        end

        def setup
          setup_php php_version
          sh.cmd "phpenv rehash", assert: false, echo: false, timing: false
          sh.cmd "composer self-update", assert: false
        end

        def announce
          sh.cmd 'hhvm --version'
          super
        end

        def install

        end

        def script

        end

        def hhvm?
          unless VALID_HHVM.include? version
            sh.echo "hhvm version given #{version}"
            sh.failure "hhvm version must be one of: #{VALID_HHVM.join(", ")}."
          end
          true
        end

        def version
          Array(config[:hhvm]).first.to_s
        end

        def php_version
          Array(config[:php] || DEFAULTS[:php]).first.to_s
        end

        def cache_slug
          super << "--hack-" << version
        end

      end
    end
  end
end
