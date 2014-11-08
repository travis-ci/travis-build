require 'shellwords'
require 'travis/build/addons/base'

module Travis
  module Build
    class Addons
      class SshKnownHosts < Base
        SUPER_USER_SAFE = true

        def before_configure
          add_ssh_known_hosts unless config.empty?
        end

        private

          def add_ssh_known_hosts
            sh.echo 'Adding ssh known hosts (BETA)', ansi: :yellow
            sh.fold 'ssh_known_hosts.0' do
              hosts.each do |host|
                add_host(host)
              end
            end
          end

          def add_host(host)
            sh.cmd "ssh-keyscan -t rsa,dsa -H #{host} 2>&1 | tee -a #{known_hosts_file}", echo: true, timing: true
          end

          def known_hosts_file
            "#{Travis::Build::HOME_DIR}/.ssh/known_hosts"
          end

          def hosts
            config.map { |host| host.gsub(/[^\w_\-\.]/, '').shellescape }
          end

          def config
            Array(super)
          end
      end
    end
  end
end
