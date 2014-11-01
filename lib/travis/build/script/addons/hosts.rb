require 'shellwords'
require 'travis/build/script/addons/base'

module Travis
  module Build
    class Script
      class Addons
        class Hosts < Base
          SUPER_USER_SAFE = true

          def before_prepare
            sh.fold 'hosts' do
              sh.cmd "sed -e 's/^\\(127\\.0\\.0\\.1.*\\)$/\\1 '#{hosts}'/' -i'.bak' /etc/hosts", sudo: true
              sh.cmd "sed -e 's/^\\(::1.*\\)$/\\1 '#{hosts}'/' -i'.bak' /etc/hosts", sudo: true
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
end
