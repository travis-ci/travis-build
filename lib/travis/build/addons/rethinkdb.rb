require 'shellwords'
require 'travis/build/addons/base'

module Travis
  module Build
    class Addons
      class Rethinkdb < Base
        SUPER_USER_SAFE = true

        RETHINKDB_GPG_KEY = '0x3A8F2399'

        def after_prepare
          sh.fold 'rethinkdb' do
            sh.if "$(uname) != 'Linux'" do
              sh.echo "The RethinkDB addon only works on Linux.", ansi: :red
            end
            sh.else do
              sh.echo "Installing RethinkDB version #{rethinkdb_version}", ansi: :yellow
              sh.cmd "service rethinkdb stop", sudo: true
              sh.cmd "apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 #{RETHINKDB_GPG_KEY}", sudo: true
              sh.cmd 'add-apt-repository "deb http://download.rethinkdb.com/apt $(lsb_release -cs) main"', sudo: true
              sh.cmd "apt-get update -qq", assert: false, sudo: true
              sh.cmd "package_version=#{rethinkdb_version}$(lsb_release -cs)"
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

