require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class FixWwdrCertificate < Base
        def apply
          sh.cmd %(if `command -v sw_vers`; then)
          sh.cmd %(  echo im doin it)
          sh.cmd %(  sudo security delete-certificate -Z 0950B6CD3D2F37EA246A1AAA20DFAADBD6FE1F75 /Library/Keychains/System.keychain)
          sh.cmd %(  wget https://developer.apple.com/certificationauthority/AppleWWDRCA.cer)
          sh.cmd %(  sudo security add-certificates -k /Library/Keychains/System.keychain AppleWWDRCA.cer)
          sh.cmd %(fi)
        end
      end
    end
  end
end
