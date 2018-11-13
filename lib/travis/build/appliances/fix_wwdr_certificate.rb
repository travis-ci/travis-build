require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class FixWwdrCertificate < Base
        def apply
          sh.if "$(command -v sw_vers)" do
            sh.cmd "sudo security delete-certificate -Z 0950B6CD3D2F37EA246A1AAA20DFAADBD6FE1F75 /Library/Keychains/System.keychain &>/dev/null", assert: false, echo: false
            sh.cmd "wget -q https://developer.apple.com/certificationauthority/AppleWWDRCA.cer", assert: false, echo: false
            sh.cmd "sudo security add-certificates -k /Library/Keychains/System.keychain AppleWWDRCA.cer &>/dev/null", assert: false, echo: false
          end
        end
      end
    end
  end
end
