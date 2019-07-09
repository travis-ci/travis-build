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

          setup_php version
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

        def install_php_on_demand(version='nightly')
          sh.echo "#{version} is not pre-installed; installing", ansi: :yellow
          if version == '7'
            setup_alias(version, '7.0')
            version = '7.0'
          end
          sh.raw archive_url_for('travis-php-archives', version, 'php')
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

        def setup_php version
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
      end
    end
  end
end
