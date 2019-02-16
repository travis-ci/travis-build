require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class GitWireProtocolV2 < Base

        def apply?
          # Git version on `xcode9.3` and android images doesn't support protocol v2
          data[:config][:osx_image].to_s.empty?
            || !%w[xcode9.3 xcode9.3-moar].include?(data[:config][:osx_image])
            || data[:config][:language] != "android"
        end

        def apply
          sh.cmd "git config --global protocol.version 2", assert: false, echo: false
        end

      end
    end
  end
end
