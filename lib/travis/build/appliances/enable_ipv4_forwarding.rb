require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class EnableIpv4Forwarding < Base
        def apply
          # To be removed once precise and trusty are gone (xenial image will be patched by January 2018)
          sh.if '("$TRAVIS_DIST" == precise || "$TRAVIS_DIST" == trusty || "$TRAVIS_DIST" == xenial)' do
            sh.raw %(echo "net.ipv4.ip_forward = 1" | sudo tee /etc/sysctl.d/99-travis-enable-ipv4-forwarding.conf > /dev/null 2>&1)
          end
        end
      end
    end
  end
end
