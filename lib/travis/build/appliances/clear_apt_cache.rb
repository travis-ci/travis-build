require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class ClearAptCache < Base
        def apply
          sh.cmd "sudo rm -rf /var/lib/apt/lists/*", echo: false
        end
      end
    end
  end
end
