require 'shellwords'
require 'travis/build/addons/base'

module Travis
  module Build
    class Addons
      class Hosts < Base
        SUPER_USER_SAFE = true

        def before_configure
          sh.fold 'hosts' do
            sh.cmd "sudo sed -e 's/^\\(127\\.0\\.0\\.1.*\\)$/\\1 '#{hosts}'/' -i'.bak' /etc/hosts"
            sh.cmd "sudo sed -e 's/^\\(::1.*\\)$/\\1 '#{hosts}'/' -i'.bak' /etc/hosts"
          end
        end

        private

          def hosts
            Array(config).join(' ').gsub(/[^\w_\-\. ]/, '').shellescape
          end
      end
    end
  end
end
