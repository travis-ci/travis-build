module Travis
  module Build
    class Script
      module Addons
        class SshKnownHosts
          SUPER_USER_SAFE = true

          def initialize(script, config)
            @script = script
            @config = [*config]
          end

          def before_checkout
            add_ssh_known_hosts
          end

          private

            attr_accessor :script, :config

            def add_ssh_known_hosts
              script.echo "Adding ssh known hosts (BETA)", ansi: :yellow unless config.empty?
              script.fold 'ssh_known_hosts.0' do
                config.each do |host|
                  script.cmd "ssh-keyscan #{host} | tee -a #{Travis::Build::HOME_DIR}/.ssh/known_hosts", assert: false
                  script.cmd "for _ip in $(dig +short #{host}) ; do " \
                             "ssh-keyscan $_ip | tee -a #{Travis::Build::HOME_DIR}/.ssh/known_hosts ; done", assert: false
                end
              end
            end
        end
      end
    end
  end
end
