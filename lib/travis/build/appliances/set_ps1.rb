require 'travis/build/appliances/base'
require 'shellwords'

module Travis
  module Build
    module Appliances
      class SetPs1 < Base
        def apply
          sh.export 'PS1', Shellwords.escape('$ '), echo: false
        end
      end
    end
  end
end
