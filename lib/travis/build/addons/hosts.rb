require 'shellwords'
require 'travis/build/addons/base'

module Travis
  module Build
    class Addons
      class Hosts < Base
        SUPER_USER_SAFE = true
        HOSTS_FILE = '/etc/hosts'
        TEMP_HOSTS_FILE = '/tmp/hosts'

        def after_prepare
          sh.fold 'hosts.before' do
            sh.newline
            sh.cmd "cat #{HOSTS_FILE}"
            sh.newline
          end
          sh.fold 'hosts' do
            sh.cmd "sed -e 's/^\\(127\\.0\\.0\\.1.*\\)$/\\1 #{hosts}/' #{HOSTS_FILE} > #{TEMP_HOSTS_FILE}"
            sh.cmd "cat #{TEMP_HOSTS_FILE} | sudo tee #{HOSTS_FILE} > /dev/null"
          end
          sh.fold 'hosts.after' do
            sh.newline
            sh.cmd "cat #{HOSTS_FILE}"
            sh.newline
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
