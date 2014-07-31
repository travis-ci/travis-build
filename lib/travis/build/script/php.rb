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

        def use_directory_cache?
          super || data.cache?(:composer)
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
          self.if '-f composer.json' do |sub|
            directory_cache.add(sub, "~/.composer") if data.cache?(:composer)
            sub.cmd "composer install #{config[:composer_args]}".strip, fold: 'install.composer'
          end
        end

        def script
          cmd 'phpunit'
        end
      end
    end
  end
end
