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
            [super].flatten
          end

          def add_ssh_known_hosts
            sh.fold 'ssh_known_hosts.0' do
              sh.echo "Adding ssh known hosts (BETA)", ansi: :yellow
              config.each do |host|
                case host
                when String
                  keyscan(host)
                when Hash
                  host, type, key = host.values_at(:host, :type, :key)
                  if host && type && key
                    sh.cmd "echo '#{host} #{type} #{key}' >> $HOME/.ssh/known_hosts", echo: true
                  else
                    sh.echo "Missing at least one of host, type, and key in the ssh_known_hosts configuration", ansi: :yellow
                  end
                end
              end
            end
          end

          def keyscan(host)
            begin
              host_uri = URI("ssh://#{host}")
            rescue => e
              sh.echo "Skipping malformed host #{Shellwords.escape(host.inspect)}", ansi: :red
              warn e
              return
            end

            unless host_uri.host
              sh.echo "Skipping malformed host #{Shellwords.escape(host.inspect)}", ansi: :red
              return
            end

            sh.if "$(uname) = 'Darwin'" do
              sh.cmd "TRAVIS_SSH_KEY_TYPES='rsa,dsa'"
            end
            sh.else do
              sh.cmd "TRAVIS_SSH_KEY_TYPES='rsa,dsa,ecdsa'"
            end
            ssh_keyscan_command = "ssh-keyscan -t $TRAVIS_SSH_KEY_TYPES"
            ssh_keyscan_command << " -p #{Shellwords.escape(host_uri.port)}" if host_uri.port
            ssh_keyscan_command << " -H #{Shellwords.escape(host_uri.host)}"
            sh.cmd "#{ssh_keyscan_command} 2>&1 | tee -a #{Travis::Build::HOME_DIR}/.ssh/known_hosts", echo: true, timing: true
          end
      end
    end
  end
end
