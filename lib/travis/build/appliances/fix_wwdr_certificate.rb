require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class FixWwdrCertificate < Base
        def apply
          sh.cmd <<-EOF
if [ $(command -v sw_vers) ]; then
  echo "Fix WWDRCA Certificate"
  sudo security delete-certificate -Z 0950B6CD3D2F37EA246A1AAA20DFAADBD6FE1F75 /Library/Keychains/System.keychain
  wget -q https://developer.apple.com/certificationauthority/AppleWWDRCA.cer
  sudo security add-certificates -k /Library/Keychains/System.keychain AppleWWDRCA.cer
fi
          EOF
        end
      end
    end
  end
end
