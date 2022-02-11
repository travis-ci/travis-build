require 'shellwords'
require 'travis/build/addons/base'

module Travis
  module Build
    class Addons
      class Rethinkdb < Base
        SUPER_USER_SAFE = true

        def after_prepare
          sh.fold 'rethinkdb' do
            sh.if "$(uname) != 'Linux'" do
              sh.echo "The RethinkDB addon only works on Linux.", ansi: :red
            end
            sh.else do
              sh.echo "Installing RethinkDB version #{rethinkdb_version}", ansi: :yellow
              sh.cmd "service rethinkdb stop", sudo: true
              sh.cmd "sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys \"539A 3A8C 6692 E6E3 F69B 3FE8 1D85 E93F 801B B43F\"", echo: true
              sh.cmd 'echo -e "\ndeb https://download.rethinkdb.com/repository/ubuntu-$(lsb_release -cs)/ $(lsb_release -cs) main" | sudo tee -a /etc/apt/sources.list.d/rethinkdb.list > /dev/null'
              sh.cmd 'travis_apt_get_update', assert: false
              sh.cmd "package_version=`apt-cache show rethinkdb | grep -F \"Version: #{rethinkdb_version}\" | sort -r | head -n 1 | awk '{printf $2}'`"
              sh.cmd "apt-get install -y -o Dpkg::Options::='--force-confnew' rethinkdb=$package_version", sudo: true, echo: true, timing: true
              sh.echo "Installing RethinkDB default instance configuration"
              sh.cmd "cp /etc/rethinkdb/default.conf.sample /etc/rethinkdb/instances.d/default.conf", sudo: true
              sh.echo "Starting RethinkDB v#{rethinkdb_version}", ansi: :yellow
              sh.cmd "service rethinkdb start", sudo: true, assert: false, echo: true, timing: true
              sh.export 'TRAVIS_RETHINKDB_VERSION', rethinkdb_version, echo: false
              sh.export 'TRAVIS_RETHINKDB_PACKAGE_VERSION', '$package_version', echo: false
              sh.cmd "rethinkdb --version", assert: false, echo: true
            end
          end
        end

        private
        def rethinkdb_version
          config.to_s.shellescape
        end
      end
    end
  end
end
