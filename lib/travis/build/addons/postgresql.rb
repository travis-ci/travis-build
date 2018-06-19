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
          if not data.is_linux?
            sh.echo "Addon PostgreSQL is not supported on #{data[:config][:os]}", ansi: :red
            return
          end
          sh.fold 'postgresql' do
            sh.export 'PATH', "/usr/lib/postgresql/#{version}/bin:$PATH", echo: false
            sh.echo "Starting PostgreSQL v#{version}", ansi: :yellow

            if data.is_precise? || data.is_trusty?
              stop_command = "service postgresql stop"
              start_command = "service postgresql start #{version}"
            else
              stop_command = "systemctl stop postgresql"
              start_command = "systemctl start postgresql@#{version}-main"
            end
            sh.cmd stop_command, assert: false, sudo: true, echo: true, timing: true
            sh.if "-d /var/ramfs && ! -d /var/ramfs/postgresql/#{version}", echo: false do
              sh.cmd "cp -rp /var/lib/postgresql/#{version} /var/ramfs/postgresql/#{version}", sudo: true, assert: false, echo: false, timing: false
            end
            sh.cmd start_command, assert: false, sudo: true, echo: true, timing: true
            [DEFAULT_PORT, DEFAULT_FALLBACK_PORT].each do |pgport|
              sh.cmd "sudo -u postgres createuser -s -p #{pgport} travis &>/dev/null", assert: false, echo: true, timing: true
              sh.cmd "sudo -u postgres createdb -O travis -p #{pgport} travis &>/dev/null", assert: false, echo: true, timing: true
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
