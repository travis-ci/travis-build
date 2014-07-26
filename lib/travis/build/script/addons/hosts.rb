require 'shellwords'

module Travis
  module Build
    class Script
      module Addons
        class Hosts
          SUPER_USER_SAFE = true

          attr_reader :sh, :config

          def initialize(script, config)
            @script = script
            @config = [config].flatten.join(' ').shellescape
          end

          def after_pre_setup
            sh.fold 'hosts' do
              sh.cmd "sudo sed -e 's/^\\(127\\.0\\.0\\.1.*\\)$/\\1 '#{config}'/' -i'.bak' /etc/hosts"
              sh.cmd "sudo sed -e 's/^\\(::1.*\\)$/\\1 '#{config}'/' -i'.bak' /etc/hosts"
            end
          end
        end
      end
    end
  end
end
