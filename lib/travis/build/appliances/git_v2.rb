require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class GitV2 < Base
        def apply
          sh.cmd "git config --global protocol.version 2"
        end

        def apply?
          config[:os] == 'osx' && config[:osx_image] && config[:osx_image] == 'xcode10.2'
        end
      end
    end
  end
end