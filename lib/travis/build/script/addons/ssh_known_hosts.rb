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
                  script.cmd "ssh-keyscan -H #{host} >> #{Travis::Build::HOME_DIR}/.ssh/known_hosts 2>/dev/null", assert: false
                end
              end
            end
        end
      end
    end
  end
end
