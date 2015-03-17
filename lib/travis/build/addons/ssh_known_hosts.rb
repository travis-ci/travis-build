require 'travis/build/addons/base'

module Travis
  module Build
    class Addons
      # SshKnownHosts accepts an array of hosts, which may be either
      # `"hostname"` or `"hostname:port"`.  The purpose of this addon is to
      # allow for the addition of arbitrary hosts to the `~/.ssh/known_hosts`
      # file *prior to* the initial git clone, hence the use of the
      # `before_checkout` hook, specifically so that git clones that include
      # ssh submodules from previously unknown domains can succeed.
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
            sh.fold 'ssh_known_hosts.0' do
              sh.echo "Adding ssh known hosts (BETA)", ansi: :yellow
              config.each do |host|
                host_uri = URI("ssh://#{host}")
                unless host_uri.host
                  sh.echo "Skipping malformed host #{host.inspect}", ansi: :red
                  next
                end
                ssh_keyscan_command = "ssh-keyscan -t rsa,dsa -H #{host_uri.host}"
                ssh_keyscan_command << " -p #{host_uri.port}" if host_uri.port
                sh.cmd "#{ssh_keyscan_command} 2>&1 | tee -a #{Travis::Build::HOME_DIR}/.ssh/known_hosts", echo: true, timing: true
              end
            end
          end
      end
    end
  end
end
