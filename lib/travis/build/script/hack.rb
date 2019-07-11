module Travis
  module Build
    class Script
      class Hack < Php
        DEFAULTS = {
          hhvm: 'hhvm',
          php: '7.2',
        }

        VALID_HHVM = %w(
          hhvm
          hhvm-dbg
          hhvm-dev
          hhvm-nightly
          hhvm-nightly-dbg
          hhvm-dev-nightly
        )

        VERSION_REGEXP = /hhvm-(\d+(\.\d+)*)(-lts)?/

        def configure
          unless VALID_HHVM.include?(version) || version =~ VERSION_REGEXP
            sh.echo "hhvm version given #{version}"
            sh.failure "hhvm version must be one of: #{VALID_HHVM.join(", ")}, or " \
              "match regular expression #{VERSION_REGEXP} (e.g., 3.27 or 3.30-lts)."
          end

          configure_hhvm
          super
        end

        def export
          super
          sh.export 'TRAVIS_PHP_VERSION', php_version, echo: false # redefine TRAVIS_PHP_VERSION
          sh.export 'TRAVIS_HACK_VERSION', version, echo: false
        end

        def setup
          if nightly?
            sh.cmd "phpenv global hhvm-nightly 3>/dev/null", assert: true
          else
            sh.cmd "phpenv global hhvm 2>/dev/null", assert: true
          end
          sh.mkdir "${TRAVIS_HOME}/.phpenv/versions/hhvm/etc/conf.d", recursive: true

          setup_php php_version
          sh.cmd "phpenv rehash", assert: false, echo: false, timing: false
          sh.cmd "composer self-update", assert: false
        end

        def announce
          sh.cmd 'hhvm --version'
          super
        end

        def install

        end

        def script

        end

        def hhvm?
          true
        end

        def php_5_3_or_older?
          false
        end

        def version
          Array(config[:hhvm]).first.to_s
        end

        def php_version
          Array(config[:php] || DEFAULTS[:php]).first.to_s
        end

        def hhvm_version
          return unless hhvm?
          if match_data = VERSION_REGEXP.match(version)
            match_data[1]
          else
            version
          end
        end

        def lts?
          version.end_with? '-lts'
        end

        def cache_slug
          super << "--hack-" << version
        end


        def configure_hhvm
          sh.if '"$(lsb_release -sc 2>/dev/null)" = "precise"' do
            sh.echo "HHVM is no longer supported on Ubuntu Precise. Please consider using Trusty with \\`dist: trusty\\`.", ansi: :yellow
            sh.raw "travis_terminate 1"
          end

          update_hhvm
          fix_hhvm_php_ini
        end

        def update_hhvm
          sh.if '"$(lsb_release -sc 2>/dev/null)"' do
            sh.fold 'update.hhvm', ansi: :yellow do
              sh.echo "Updating HHVM", ansi: :yellow
              sh.raw 'sudo find /etc/apt -type f -exec sed -e "/hhvm\\.com/d" -i.bak {} \;'

              if lts?
                sh.cmd "echo \"deb [ arch=amd64 ] http://dl.hhvm.com/ubuntu $(lsb_release -sc)-lts-#{hhvm_version} main\" | sudo tee -a /etc/apt/sources.list >&/dev/null"
                sh.raw 'sudo apt-get purge hhvm >&/dev/null'
              else
                # use latest
                sh.cmd 'echo "deb [ arch=amd64 ] http://dl.hhvm.com/ubuntu $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list >&/dev/null'
              end

              sh.cmd 'sudo apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xB4112585D386EB94'
              sh.cmd 'travis_apt_get_update'
              hhvm_install_cmd
            end
          end
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

        def hhvm_install_cmd
          ver = VALID_HHVM.include?(version) ? version : 'hhvm'
          sh.cmd "sudo apt-get install #{ver} -y 2>&1 >/dev/null", assert: true, timing: true, echo: true
        end

      end
    end
  end
end
