# frozen_string_literal: true

require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class FixContainerBasedTrusty < Base
        def apply
          sh.if sh_is_linux? do
            sh.if sh_is_trusty? do
              # NOTE: no fixes currently needed :tada:
            end
          end
        end

        def apply?
          false
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
