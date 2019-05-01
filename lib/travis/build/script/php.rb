module Travis
  module Build
    class Script
      class Php < Script
        DEFAULTS = {
          php:      '7.2',
          composer: '--no-interaction --prefer-source'
        }

        DEPRECATIONS = [
          {
            name: 'PHP',
            current_default: DEFAULTS[:php],
            new_default: '7.2',
            cutoff_date: '2019-03-12',
          }
        ]

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

          if php_5_3_or_older?
            sh.if "$(lsb_release -sc 2>/dev/null) != precise" do
              sh.echo "PHP #{version} is supported only on Precise.", ansi: :red
              sh.echo "See https://docs.travis-ci.com/user/reference/trusty#PHP-images on how to test PHP 5.3 on Precise.", ansi: :red
              sh.echo "Terminating.", ansi: :red
              sh.failure
            end
          end

          if hhvm?
            if nightly?
              sh.cmd "phpenv global hhvm-nightly 3>/dev/null", assert: true
            else
              sh.cmd "phpenv global hhvm 2>/dev/null", assert: true
            end
            sh.mkdir "${TRAVIS_HOME}/.phpenv/versions/hhvm/etc/conf.d", recursive: true
          else
            sh.cmd "phpenv global #{version} 2>/dev/null", assert: false
            sh.if "$? -ne 0" do
              install_php_on_demand(version)
            end
            unless php_5_3_or_older?
              sh.else do
                sh.fold "pearrc" do
                  sh.echo "Writing ${TRAVIS_HOME}/.pearrc", ansi: :yellow
                  overwrite_pearrc(version)
                  sh.cmd "pear config-show", echo: true
                end
              end
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
          sh.raw '_phpunit_bin=$(jq -r .config[\"bin-dir\"] $TRAVIS_BUILD_DIR/composer.json 2>/dev/null)/phpunit'
          sh.if "-n $COMPOSER_BIN_DIR && -x $COMPOSER_BIN_DIR/phpunit" do
            sh.cmd '$COMPOSER_BIN_DIR/phpunit'
          end
          sh.elif "-n $_phpunit_bin && -x $_phpunit_bin" do
            sh.raw "echo \"$ $_phpunit_bin\""
            sh.cmd "${_phpunit_bin}", echo: false
          end
          sh.elif "-x $TRAVIS_BUILD_DIR/vendor/bin/phpunit" do
            sh.cmd "$TRAVIS_BUILD_DIR/vendor/bin/phpunit"
          end
          sh.else do
            sh.cmd 'phpunit'
          end
        end

        def cache_slug
          super << "--php-" << version
        end

        private

        def version
          Array(config[:php]).first.to_s
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
          sh.if '"$(lsb_release -sc 2>/dev/null)" = "precise"' do
            sh.echo "HHVM is no longer supported on Ubuntu Precise. Please consider using Trusty with \\`dist: trusty\\`.", ansi: :yellow
            sh.raw "travis_terminate 1"
          end

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
                sh.raw "echo \"deb [ arch=amd64 ] http://dl.hhvm.com/ubuntu $(lsb_release -sc)-lts-#{hhvm_version} main\" | sudo tee -a /etc/apt/sources.list >&/dev/null"
                sh.raw 'sudo apt-get purge hhvm >&/dev/null'
              else
                # use latest
                sh.cmd 'echo "deb [ arch=amd64 ] http://dl.hhvm.com/ubuntu $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list'
              end

              sh.cmd 'sudo apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xB4112585D386EB94'
              sh.cmd 'travis_apt_get_update'
              sh.cmd "sudo apt-get install -y hhvm", timing: true, echo: true, assert: true
            end
          end
        end

        def install_hhvm_nightly
          sh.echo 'Installing HHVM nightly', ansi: :yellow
          sh.cmd 'travis_apt_get_update'
          sh.cmd 'sudo apt-get install hhvm-nightly -y 2>&1 >/dev/null'
          sh.cmd 'test -d ${TRAVIS_HOME}/.phpenv/versions/hhvm-nightly || cp -r ${TRAVIS_HOME}/.phpenv/versions/hhvm{,-nightly}', echo: false
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
          sh.echo "Downloading archive: ${archive_url}", ansi: :yellow
          sh.cmd "curl -s -o archive.tar.bz2 $archive_url && tar xjf archive.tar.bz2 --directory /", echo: true, assert: false
          sh.cmd "rm -f archive.tar.bz2", echo: false
        end

        def setup_alias(from, to)
          sh.cmd "ln -s ~/.phpenv/versions/#{to} ~/.phpenv/versions/#{from}", echo: false
        end

        def composer_self_update
          unless version =~ /^5\.2/
            sh.if '-n $(composer --version | grep -o "version [^ ]*1\\.0-dev")' do
              sh.cmd "composer self-update 1.0.0", assert: false
            end
            sh.cmd "composer self-update", assert: false
          end
        end

        def php_5_3_or_older?
          !hhvm? && !nightly? && Gem::Version.new(version) < Gem::Version.new('5.4')
        rescue
          false
        end

        def overwrite_pearrc(version)
          pear_config = %q(
            [
              'preferred_state' => "stable",
              'temp_dir'     => "/tmp/pear/install",
              'download_dir' => "/tmp/pear/install",
              'bin_dir'      => "/home/travis/.phpenv/versions/__VERSION__/bin",
              'php_dir'      => "/home/travis/.phpenv/versions/__VERSION__/share/pear",
              'doc_dir'      => "/home/travis/.phpenv/versions/__VERSION__/docs",
              'data_dir'     => "/home/travis/.phpenv/versions/__VERSION__/data",
              'cfg_dir'      => "/home/travis/.phpenv/versions/__VERSION__/cfg",
              'www_dir'      => "/home/travis/.phpenv/versions/__VERSION__/www",
              'man_dir'      => "/home/travis/.phpenv/versions/__VERSION__/man",
              'test_dir'     => "/home/travis/.phpenv/versions/__VERSION__/tests",
              '__channels'   => [
                '__uri' => [],
                'doc.php.net' => [],
                'pecl.php.net' => []
              ],
              'auto_discover' => 1
            ]
          ).gsub("__VERSION__", version)

          sh.cmd "echo '<?php error_reporting(0); echo serialize(#{pear_config}) ?>' | php > ${TRAVIS_HOME}/.pearrc", echo: false
        end
      end
    end
  end
end
