require 'shellwords'

module Travis
  module Build
    class Script
      module Addons
        class Postgresql
          SUPER_USER_SAFE = true

          def initialize(script, config)
            @script = script
            @postgresql_version = config.to_s.shellescape
          end

          def after_pre_setup
            @script.fold 'postgresql' do |sh|
              sh.set "PATH", "/usr/lib/postgresql/#{@postgresql_version}/bin:$PATH", echo: false
              sh.echo "Starting PostgreSQL v#{@postgresql_version}", ansi: :yellow
              sh.cmd "sudo service postgresql stop", assert: false
              sh.if( "-d /var/ramfs && ! -d /var/ramfs/postgresql/#{@postgresql_version}" ) do |no_ramfs|
                no_ramfs.cmd "sudo cp -rp /var/lib/postgresql/#{@postgresql_version} /var/ramfs/postgresql/#{@postgresql_version}", assert: false, echo: false
              end
              sh.cmd "sudo service postgresql start #{@postgresql_version}", assert: false
            end
          end
        end
      end
    end
  end
end
