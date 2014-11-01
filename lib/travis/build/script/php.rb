module Travis
  module Build
    class Script
      class Php < Script
        DEFAULTS = {
          php:      '5.5',
          composer: '--no-interaction --prefer-source'
        }

        def cache_slug
          super << "--php-" << config[:php].to_s
        end

        def use_directory_cache?
          super || data.cache?(:composer)
        end

        def export
          super
          sh.export 'TRAVIS_PHP_VERSION', config[:php], echo: false
        end

        def setup
          super
          sh.cmd "phpenv global #{config[:php]}", assert: true
        end

        def announce
          super
          sh.cmd 'php --version'
          sh.cmd 'composer --version' unless config[:php] == '5.2'
        end

        def before_install
          # sh.if '-f composer.json' do
          #   sh.cmd 'composer self-update', fold: 'before_install.update_composer'
          # end
        end

        def install
          # sh.if '-f composer.json' do
          #   directory_cache.add(sub, '~/.composer') if data.cache?(:composer)
          #   sh.cmd "composer install #{config[:composer_args]}".strip, fold: 'install.composer'
          # end
        end

        def script
          sh.cmd 'phpunit'
        end
      end
    end
  end
end
