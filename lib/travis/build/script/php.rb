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
          sh.cmd "phpenv global #{version} 2>/dev/null", assert: false
          sh.if "$? -ne 0" do
            install_php_on_demand(version)
            sh.cmd "phpenv global #{version}", assert: true
          end
          sh.cmd "phpenv rehash", assert: false, echo: false, timing: false
        end

        def announce
          super
          sh.cmd 'php --version'
          sh.cmd 'composer --version' unless version == '5.2'
          sh.echo '${ANSI_RESET}', echo: false
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
          if nightly?
            install_hhvm_nightly
          elsif hhvm?
            update_hhvm
          end
          fix_hhvm_php_ini
        end

        def update_hhvm
          sh.if '"$(lsb_release -sc 2>/dev/null)" = "precise"' do
            sh.echo 'Updating HHVM', ansi: :yellow
            sh.cmd 'sudo apt-get update -qq'
            sh.cmd 'sudo apt-get install hhvm 2>&1 >/dev/null'
          end
        end

        def install_hhvm_nightly
          sh.if '"$(lsb_release -sc 2>/dev/null)" = "precise"' do
            sh.echo "HHVM nightly is no longer supported on Ubuntu Precise. See https://github.com/travis-ci/travis-ci/issues/3788 and https://github.com/facebook/hhvm/issues/5220", ansi: :yellow
            sh.raw "travis_terminate 1"
          end
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
          sh.raw "sudo chown $(whoami) #{ini_file_path}"
          # Ensure that the configured session storage directory exists if
          # specified in the ini file.
          sh.raw "grep session.save_path #{ini_file_path} | cut -d= -f2 | sudo xargs mkdir -m 01733 -p"
        end

        def install_php_on_demand(version='nightly')
          sh.echo "#{version} is not pre-installed; installing", ansi: :yellow
          if version == '7'
            setup_alias(version, '7.0')
            version = '7.0'
          end
          sh.cmd "curl -s -o archive.tar.bz2 #{archive_url_for('travis-php-archives', version)} && tar xjf archive.tar.bz2 --directory /", echo: false, assert: false
          sh.cmd "rm -f archive.tar.bz2", echo: false
        end

        def setup_alias(from, to)
          sh.cmd "ln -s ~/.phpenv/versions/#{to} ~/.phpenv/versions/#{from}", echo: false
        end
      end
    end
  end
end
