require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class DisableSudo < Base
        def apply
          sh.file "${TRAVIS_TMPDIR}/fake-sudo", bash('travis_fake_sudo')
          sh.raw bash('travis_disable_sudo')
          sh.cmd 'travis_disable_sudo'
        end

        def apply?
          super && data.disable_sudo?
        end
      end
    end
  end
end
