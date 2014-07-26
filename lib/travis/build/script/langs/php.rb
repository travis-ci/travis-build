module Travis
  module Build
    class Script
      class Php < Script
        DEFAULTS = {
          php: '5.3'
        }

        def export
          super
          set 'TRAVIS_PHP_VERSION', version, echo: true
        end

        def setup
          super
          cmd "phpenv global #{version}", echo: true
        end

        def announce
          super
          cmd 'php --version', echo: true, timing: false
          cmd 'composer --version', echo: true, timing: false
        end

        def install
          # # composer is not yet ready for prime time. MK.
          # sh.if '-f composer.json', "composer install #{config[:composer_args]}".strip
        end

        def script
          cmd 'phpunit', echo: true
        end

        def cache_slug
          super << "--php-" << version
        end

        def version
          config[:php].to_s
        end
      end
    end
  end
end

