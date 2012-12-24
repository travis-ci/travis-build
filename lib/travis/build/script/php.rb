module Travis
  module Build
    class Script
      class Php < Script
        DEFAULTS = {
          php: '5.3'
        }

        def export
          super
          set 'TRAVIS_PHP_VERSION', config[:php]
        end

        def setup
          super
          cmd "phpenv global #{config[:php]}", assert: true
        end

        def announce
          super
          cmd 'php --version'
        end

        def install
          # # composer is not yet ready for prime time. MK.
          # sh_if '-f composer.json', "composer install #{config.composer_args}".strip
        end

        def script
          cmd 'phpunit'
        end
      end
    end
  end
end

