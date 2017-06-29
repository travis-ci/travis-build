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
          sh.fold 'mariadb' do
            sh.echo "Installing MariaDB version #{mariadb_version}", ansi: :yellow
            sh.cmd "service mysql stop", sudo: true
            sh.cmd "apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 #{MARIADB_GPG_KEY}", sudo: true
            sh.cmd 'add-apt-repository "deb http://%p/mariadb/repo/%p/ubuntu $(lsb_release -cs) main"' % [MARIADB_MIRROR, mariadb_version], sudo: true
            sh.cmd "apt-get update -qq", assert: false, sudo: true
            sh.cmd "apt-get install -y -o Dpkg::Options::='--force-confnew' mariadb-server mariadb-server-#{mariadb_version} #{mariadb_client}", sudo: true, echo: true, timing: true
            sh.echo "Starting MariaDB v#{mariadb_version}", ansi: :yellow
            sh.cmd "service mysql start", sudo: true, assert: false, echo: true, timing: true
            sh.export 'TRAVIS_MARIADB_VERSION', mariadb_version, echo: false
            sh.cmd "mysql --version", assert: false, echo: true
          end
        end

        private
        def mariadb_version
          config.to_s.shellescape
        end

        def mariadb_client
          if config >= 10.2
            # As of MariaDB 10.2 the headers are included
            'libmariadbclient18'
          else
            'libmariadbclient18 libmariadbclient-dev'
          end
        end
      end
    end
  end
end
