module Travis
  module Build
    class Script
      class Php < Script
        DEFAULTS = {
          php: '5.3'
        }

        def cache_slug
          super << "--php-" << config[:php].to_s
        end

        def export
          super
          set 'TRAVIS_PHP_VERSION', config[:php], echo: false
        end

        def setup
          super
          cmd "phpenv global #{config[:php]}", assert: true
        end

        def announce
          super
          cmd 'php --version'
          cmd 'composer --version'
        end

        def install
          # # composer is not yet ready for prime time. MK.
          # self.if '-f composer.json', "composer install #{config[:composer_args]}".strip
        end

        def script
          cmd 'phpunit'
        end
      end
    end
  end
end

