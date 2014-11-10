module Travis
  module Build
    class Script
      class Php < Script
        DEFAULTS = {
          php:      '5.5',
          composer: '--no-interaction --prefer-source'
        }

        def configure
          super
          configure_hhvm if hhvm?
        end

        def export
          super
          sh.export 'TRAVIS_PHP_VERSION', version, echo: false
        end

        def setup
          super
          sh.cmd "phpenv global #{version}", assert: true
        end

        def announce
          super
          sh.cmd 'php --version', timing: true
          # sh.cmd 'composer --version', timing: true unless version == '5.2'
          sh.cmd 'composer --version', timing: true unless config[:php] == '5.2'
        end

        def before_install
          # sh.if '-f composer.json' do
          #   sh.cmd 'composer self-update', fold: 'before_install.update_composer'
          # end
        end

        def install
          # sh.if '-f composer.json' do
          #   directory_cache.add('~/.composer') if data.cache?(:composer)
          #   sh.cmd "composer install #{composer_args}".strip, fold: 'install.composer'
          # end
        end

        def script
          sh.cmd 'phpunit'
        end

        def cache_slug
          super << "--php-" << version
        end

        private

        def version
          config[:php].to_s
        end

        def hhvm?
          version.include?('hhvm')
        end

        def nightly?
          version.include?('nightly')
        end

        def composer_args
          config[:composer_args]
        end

        def configure_hhvm
          install_hhvm_nightly if nightly?
          fix_hhvm_php_ini
        end

        def install_hhvm_nightly
          sh.echo 'Installing HHVM nightly', ansi: :yellow
          sh.cmd 'sudo apt-get update -qq'
          sh.cmd 'sudo apt-get install hhvm-nightly 2>&1 >/dev/null'
        end

        def fix_hhvm_php_ini
          sh.echo 'Modifying HHVM init file', ansi: :yellow
          ini_file_path = '/etc/hhvm/php.ini'
          ini_file_addition = <<-EOF
date.timezone = "UTC"
hhvm.libxml.ext_entity_whitelist=file,http,https
          EOF
          sh.raw "sudo mkdir -p $(dirname #{ini_file_path}); echo '#{ini_file_addition}' | sudo tee -a #{ini_file_path} > /dev/null"
        end
      end
    end
  end
end
