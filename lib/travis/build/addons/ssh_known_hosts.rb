require 'travis/build/addons/base'

module Travis
  module Build
    class Addons
      class SshKnownHosts < Base
        SUPER_USER_SAFE = true

        def before_checkout
          add_ssh_known_hosts unless config.empty?
        end

        private

          def config
            Array(super)
          end

          def add_ssh_known_hosts
            sh.echo "Adding ssh known hosts (BETA)", ansi: :yellow
            sh.fold 'ssh_known_hosts.0' do
              config.each do |host|
                sh.cmd "ssh-keyscan -t rsa,dsa -H #{host} 2>&1 | tee -a #{Travis::Build::HOME_DIR}/.ssh/known_hosts", echo: true, timing: true
              end
            end
          end
      end
    end
  end
end
