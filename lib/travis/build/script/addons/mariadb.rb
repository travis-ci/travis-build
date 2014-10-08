require 'shellwords'

module Travis
  module Build
    class Script
      module Addons
        class MariaDB
          SUPER_USER_SAFE = true

          def initialize(script, config)
            @script = script
            @mariadb_version = config.to_s.shellescape
          end

          def after_pre_setup
            @script.fold 'mariadb' do |sh|
              sh.echo "Installing MariaDB version #{@mariadb_version}", ansi: :yellow
              sh.cmd "sudo apt-get install python-software-properties", assert: false, echo: false
              sh.cmd "sudo apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xcbcb082a1bb943db", assert: false, echo: false
              sh.cmd "sudo add-apt-repository 'deb http://nyc2.mirrors.digitalocean.com/mariadb/repo/#{@mariadb_version}/ubuntu precise main'", echo: false
              sh.echo "Starting MariaDB v#{@mariadb_version}", ansi: :yellow
              sh.cmd "sudo apt-get update -qq", assert: false
              sh.cmd "sudo apt-get install -o Dpkg::Options::='--force-confnew' mariadb-server"
              sh.cmd "sudo service mysql start"
            end
          end
        end
      end
    end
  end
end
