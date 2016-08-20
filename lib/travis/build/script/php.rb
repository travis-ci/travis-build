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
          if hhvm?
            sh.cmd "phpenv global hhvm", assert: true
          else
            sh.cmd "phpenv global #{version} 2>/dev/null", assert: false
            sh.if "$? -ne 0" do
              install_php_on_demand(version)
            end
            sh.cmd "phpenv global #{version}", assert: true
          end
          sh.cmd "phpenv rehash", assert: false, echo: false, timing: false
          composer_self_update
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
          version.start_with?('hhvm')
        end

        def hhvm_version
          return unless hhvm?
          if match_data = /-(\d+(?:\.\d+)*)$/.match(version)
            match_data[1]
          end
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
          sh.if '"$(lsb_release -sc 2>/dev/null)"' do
            sh.fold 'update.hhvm', ansi: :yellow do
              sh.echo "Updating HHVM", ansi: :yellow
              sh.raw 'sudo find /etc/apt -type f -exec sed -e "/hhvm\\.com/d" -i.bak {} \;'

              if hhvm_version
                sh.raw "echo \"deb http://dl.hhvm.com/ubuntu $(lsb_release -sc)-lts-#{hhvm_version} main\" | sudo tee -a /etc/apt/sources.list >&/dev/null"
                sh.raw 'sudo apt-get purge hhvm >&/dev/null'
              else
                # use latest
                sh.cmd 'echo "deb http://dl.hhvm.com/ubuntu $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list'
              end

              sh.cmd 'sudo apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0x5a16e7281be7a449'
              sh.cmd 'sudo apt-get update -qq'
              sh.cmd "sudo apt-get install -y hhvm", timing: true, echo: true, assert: true
            end
          end
        end

        def install_hhvm_nightly
          sh.if '"$(lsb_release -sc 2>/dev/null)" = "precise"' do
            sh.echo "HHVM nightly is no longer supported on Ubuntu Precise. See https://github.com/travis-ci/travis-ci/issues/3788 and https://github.com/facebook/hhvm/issues/5220", ansi: :yellow
            sh.raw "travis_terminate 1"
          end
          sh.echo 'Installing HHVM nightly', ansi: :yellow
          sh.cmd 'sudo apt-get update -qq'
          sh.cmd 'sudo apt-get install hhvm-nightly -y 2>&1 >/dev/null'
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
          sh.raw archive_url_for('travis-php-archives', version)
          sh.cmd "curl -s -o archive.tar.bz2 $archive_url && tar xjf archive.tar.bz2 --directory /", echo: false, assert: false
          sh.cmd "rm -f archive.tar.bz2", echo: false
        end

        def setup_alias(from, to)
          sh.cmd "ln -s ~/.phpenv/versions/#{to} ~/.phpenv/versions/#{from}", echo: false
        end

        def composer_self_update
          sh.cmd "composer self-update", assert: false unless version =~ /^5\.2/
        end
      end
    end
  end
end
