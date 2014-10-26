require 'shellwords'

module Travis
  module Build
    class Script
      module Addons
        class Hosts
          SUPER_USER_SAFE = true

          attr_reader :sh, :config

          def initialize(sh, config)
            @sh = sh
            @config = [config].flatten
          end

          def after_pre_setup
            sh.fold 'hosts' do
              sh.raw "sudo sed -e 's/^\\(127\\.0\\.0\\.1.*\\)$/\\1 '#{config.join(' ').shellescape}'/' -i'.bak' /etc/hosts"
              sh.raw "sudo sed -e 's/^\\(::1.*\\)$/\\1 '#{config.join(' ').shellescape}'/' -i'.bak' /etc/hosts"
            end
          end
        end
      end
    end
  end
end
