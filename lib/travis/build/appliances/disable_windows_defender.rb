require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class DisableWindowsDefender< Base
        def apply
          sh.echo "Disabling Windows Defender", ansi: :yellow
          sh.cmd 'powershell -Command Set-MpPreference -DisableArchiveScanning \\$true', echo: true
          sh.cmd 'powershell -Command Set-MpPreference -DisableRealtimeMonitoring \\$true', echo: true
          sh.cmd 'powershell -Command Set-MpPreference -DisableBehaviorMonitoring \\$true', echo: true
        end

        def apply?
          windows?
        end
      end
    end
  end
end
