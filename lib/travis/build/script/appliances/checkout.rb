require 'travis/build/script/appliances/base'

module Travis
  module Build
    class Script
      module Appliances
        class Checkout < Base
          def apply
            Git.new(sh, data).checkout
          end
        end
      end
    end
  end
end
