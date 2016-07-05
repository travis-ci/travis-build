require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class CleanUpPath < Base
        def apply
          sh.export 'PATH', "$(echo $PATH | sed -e 's/::/:/')", echo: false
        end
      end
    end
  end
end
