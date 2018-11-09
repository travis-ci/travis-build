# frozen_string_literal: true

require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class FixSudoEnabledTrusty < Base
        def apply
          sh.if sh_is_linux? do
            sh.if sh_is_trusty? do
              sh.cmd 'unset _JAVA_OPTIONS', echo: false
              sh.cmd 'unset MALLOC_ARENA_MAX', echo: false
            end
          end
        end

        def apply?
          super && !data.disable_sudo?
        end

        private

        def sh_is_linux?
          '$(uname) = Linux'
        end

        def sh_is_trusty?
          '$(lsb_release -sc 2>/dev/null) = trusty'
        end
      end
    end
  end
end
