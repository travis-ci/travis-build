module Travis
  module Build
    class Script
      class Php < Script
        DEFAULTS = {
          php: '5.3'
        }

        def export
          super
          sh.export 'TRAVIS_PHP_VERSION', version
        end

        def setup
          super
          sh.cmd "phpenv global #{version}"
        end

        def announce
          super
          sh.cmd 'php --version'
          sh.cmd 'composer --version'
        end

        def install
          # # composer is not yet ready for prime time. MK.
          # sh.if '-f composer.json', "composer install #{config[:composer_args]}".strip
        end

        def script
          sh.cmd 'phpunit'
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

