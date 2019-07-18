module Travis
  module Build
    class Script
      class Hack < Php
        DEFAULTS = {
          hhvm: 'hhvm',
          php: '7.2',
        }

        HHVM_VERSION_REGEXP = /
          (?:^hhvm$|^$) # 'hhvm' or empty
          |
          (hhvm-)? # optional 'hhvm-' prefix
          ((?<num>\d+(\.\d+)*)(?<lts>-lts)?$ # numeric version with optional '-lts' suffix
            |
            (?<name> # any recognized name
              dbg$|
              dev$|
              nightly$|
              nightly-dbg$|
              dev-nightly$
            )
          )
        /x

        attr_accessor :hhvm_version, :hhvm_package_name, :lts_p

        def configure
          unless config[:os] == 'linux'
            sh.failure "Currently, Hack is supported only on Linux"
            return
          end
          super
        end

        def export
          super
          sh.export 'TRAVIS_PHP_VERSION', php_version, echo: false # redefine TRAVIS_PHP_VERSION
          sh.export 'TRAVIS_HACK_VERSION', version, echo: false
        end

        def setup
          sh.cmd "phpenv global hhvm 3>/dev/null", assert: true
          sh.mkdir "${TRAVIS_HOME}/.phpenv/versions/hhvm/etc/conf.d", recursive: true

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
