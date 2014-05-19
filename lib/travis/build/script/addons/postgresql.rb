module Travis
  module Build
    class Script
      module Addons
        class Postgresql
          REQUIRES_SUPER_USER = true

          def initialize(script, config)
            @script = script
            @postgresql_version = config.to_s
          end

          def before_install
            @script.fold('postgresql') do |script|
              script.set "PATH", "/usr/lib/postgresql/#{@postgresql_version}/bin:$PATH", echo: false, assert: false
              script.cmd "echo -e \"\033[33;1mStart PostgreSQL v#{@postgresql_version}\033[0m\"; ", assert: false, echo: false
              script.cmd "sudo service postgresql stop", assert: false
              script.cmd "sudo service postgresql start #{@postgresql_version}", assert: false
            end
          end
        end
      end
    end
  end
end

