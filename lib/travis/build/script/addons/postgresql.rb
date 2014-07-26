require 'shellwords'

module Travis
  module Build
    class Script
      module Addons
        class Postgresql
          SUPER_USER_SAFE = true

          attr_reader :sh, :version

          def initialize(sh, config)
            @sh = sh
            @version = config.to_s.shellescape
          end

          def after_pre_setup
            sh.fold 'postgresql' do
              set "PATH", "/usr/lib/postgresql/#{version}/bin:$PATH", echo: false
              echo "Starting PostgreSQL v#{version}", ansi: :green
              cmd "sudo service postgresql stop", assert: false
              cmd "sudo service postgresql start #{version}", assert: false
            end
          end
        end
      end
    end
  end
end
