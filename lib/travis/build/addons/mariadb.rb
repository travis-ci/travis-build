require 'shellwords'
require 'travis/build/addons/base'

module Travis
  module Build
    class Addons
      class Mariadb < Base
        SUPER_USER_SAFE = true

        MARIADB_GPG_KEY = '0xcbcb082a1bb943db'
        MARIADB_MIRROR  = 'nyc2.mirrors.digitalocean.com'

        def after_prepare
          if config.is_a? Hash
            if conditional.conditions.empty?
              run
            else
              sh.if(conditional.conditions) do
                run
              end

              sh.else do
                conditional.warning_messages
              end
            end

            return
          end

          run
        end

        def warning_message_template
          "Skipping MariaDB addon because " + '%s'
        end

        private
        def mariadb_version
          @mariadb_version ||=
            if config.is_a? Hash
              config.delete(:version).to_s.shellescape
            else
              config.to_s.shellescape
            end
        end

        def run
          sh.fold 'mariadb' do
            sh.echo "Installing MariaDB version #{mariadb_version}", ansi: :yellow
            sh.cmd "service mysql stop", sudo: true
            sh.cmd "apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 #{MARIADB_GPG_KEY}", sudo: true
            sh.cmd 'add-apt-repository "deb http://%p/mariadb/repo/%p/ubuntu $(lsb_release -cs) main"' % [MARIADB_MIRROR, mariadb_version], sudo: true
            sh.cmd "apt-get update -qq", assert: false, sudo: true
            sh.cmd "PACKAGES='mariadb-server mariadb-server-#{mariadb_version}'", echo: true
            sh.cmd "if [[ $(lsb_release -cs) = 'precise' ]]; then PACKAGES=\"${PACKAGES} libmariadbclient-dev\"; fi", echo: true
            sh.cmd "apt-get install -y -o Dpkg::Options::='--force-confnew' $PACKAGES", sudo: true, echo: true, timing: true
            sh.echo "Starting MariaDB v#{mariadb_version}", ansi: :yellow
            sh.cmd "service mysql start", sudo: true, assert: false, echo: true, timing: true
            sh.export 'TRAVIS_MARIADB_VERSION', mariadb_version, echo: false
            sh.cmd "mysql --version", assert: false, echo: true
          end
        end
      end
    end
  end
end
