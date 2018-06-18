require 'shellwords'
require 'travis/build/addons/base'

module Travis
  module Build
    class Addons
      class Postgresql < Base
        SUPER_USER_SAFE = true

        DEFAULT_PORT = 5432
        DEFAULT_FALLBACK_PORT = 5433

        def after_prepare
          sh.fold 'postgresql' do
            sh.if '! $(travis_is_linux)' do
              sh.echo "Addon PostgreSQL is not supported on #{data[:config][:os]}", ansi: :red
            end
            sh.else do
              sh.export 'PATH', "/usr/lib/postgresql/#{version}/bin:$PATH", echo: false
              sh.echo "Starting PostgreSQL v#{version}", ansi: :yellow
              sh.if '$(travis_has_systemd)' do
                sh.cmd 'systemctl stop postgresql', assert: false, sudo: true, echo: true, timing: true
              end
              sh.else do
                sh.cmd 'service postgresql stop', assert: false, sudo: true, echo: true, timing: true
              end
              sh.if "-d /var/ramfs && ! -d /var/ramfs/postgresql/#{version}", echo: false do
                sh.cmd "cp -rp /var/lib/postgresql/#{version} /var/ramfs/postgresql/#{version}", sudo: true, assert: false, echo: false, timing: false
              end
              sh.if '$(travis_has_systemd)' do
                sh.cmd "systemctl start postgresql@#{version}-main", assert: false, sudo: true, echo: true, timing: true
              end
              sh.else do
                sh.cmd "service postgresql start #{version}", assert: false, sudo: true, echo: true, timing: true
              end
              [DEFAULT_PORT, DEFAULT_FALLBACK_PORT].each do |pgport|
                sh.cmd "sudo -u postgres createuser -s -p #{pgport} travis &>/dev/null", assert: false, echo: true, timing: true
                sh.cmd "sudo -u postgres createdb -O travis -p #{pgport} travis &>/dev/null", assert: false, echo: true, timing: true
              end
            end
          end
        end

        private

          def version
            config.to_s.shellescape
          end
      end
    end
  end
end
