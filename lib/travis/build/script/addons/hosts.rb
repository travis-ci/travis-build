require 'shellwords'

module Travis
  module Build
    class Script
      module Addons
        class Hosts
          SUPER_USER_SAFE = true

          attr_reader :sh, :hosts

          def initialize(script, config)
            @sh = script.sh
            @hosts = [config].flatten.join(' ').shellescape
          end

          def after_pre_setup
            sh.fold 'hosts' do
              sh.cmd "sed -e 's/^\\(127\\.0\\.0\\.1.*\\)$/\\1 '#{hosts}'/' -i'.bak' /etc/hosts", sudo: true
              sh.cmd "sed -e 's/^\\(::1.*\\)$/\\1 '#{hosts}'/' -i'.bak' /etc/hosts", sudo: true
            end
          end
        end
      end
    end
  end
end
