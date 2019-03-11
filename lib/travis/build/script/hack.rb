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
        )

        VERSION_REGEXP = /\d+\.\d+(-lts)?/

        def configure
          unless VALID_HHVM.include?(version) || version =~ VERSION_REGEXP
            sh.echo "hhvm version given #{version}"
            sh.failure "hhvm version must be one of: #{VALID_HHVM.join(", ")}, or " \
              "match regular expression #{VERSION_REGEXP} (e.g., 3.27 or 3.30-lts)."
          end

          super
        end

        def export
          super
          sh.export 'TRAVIS_PHP_VERSION', php_version, echo: false # redefine TRAVIS_PHP_VERSION
          sh.export 'TRAVIS_HACK_VERSION', version, echo: false
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
          true
        end

        def php_5_3_or_older?
          false
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
