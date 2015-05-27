require 'shellwords'
require 'travis/build/addons/base'

module Travis
  module Build
    class Addons
      class Hosts < Base
        SUPER_USER_SAFE = true
        HOSTS_FILE = '/etc/hosts'

        def after_prepare
          sh.fold 'hosts.before' do
            sh.echo ""
            sh.cmd "cat #{HOSTS_FILE}"
          end
          sh.fold 'hosts' do
            sh.cmd "HOSTS_FILE_CONTENT=$(sed -e 's/^\\(127\\.0\\.0\\.1.*\\)$/\\1 #{hosts}/' #{HOSTS_FILE} | sed -e 's/^\\(::1.*\\)$/\\1 #{hosts}/')"
            sh.cmd "echo $HOSTS_FILE_CONTENT | sudo tee #{HOSTS_FILE} > /dev/null"
          end
          sh.fold 'hosts.after' do
            sh.echo ""
            sh.cmd "cat #{HOSTS_FILE}"
          end
        end

        private

          def hosts
            Array(config).join(' ').shellescape
          end
      end
    end
  end
end
