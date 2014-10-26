require 'shellwords'

module Travis
  module Build
    class Script
      module Addons
        class Postgresql
          SUPER_USER_SAFE = true

          attr_reader :sh

          def initialize(sh, config)
            @sh = sh
            @postgresql_version = config.to_s.shellescape
          end

          def after_pre_setup
            sh.fold 'postgresql' do
              sh.export "PATH", "/usr/lib/postgresql/#{@postgresql_version}/bin:$PATH", echo: false
              sh.echo "Starting PostgreSQL v#{@postgresql_version}", ansi: :yellow
              sh.cmd "sudo service postgresql stop", assert: false
              sh.cmd "sudo service postgresql start #{@postgresql_version}", assert: false
            end
          end
        end
      end
    end
  end
end
