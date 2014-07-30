require 'shellwords'

module Travis
  module Build
    class Script
      module Addons
        class Postgresql
          SUPER_USER_SAFE = true

          attr_reader :sh, :version

          def initialize(script, config)
            @sh = script.sh
            @version = config.to_s.shellescape
          end

          def after_pre_setup
            sh.fold 'postgresql' do
              sh.export "PATH", "/usr/lib/postgresql/#{version}/bin:$PATH", echo: false
              sh.echo "Starting PostgreSQL v#{version}", ansi: :green
              sh.cmd "service postgresql stop", assert: false, sudo: true
              sh.cmd "service postgresql start #{version}", assert: false, sudo: true
            end
          end
        end
      end
    end
  end
end
