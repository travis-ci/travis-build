require 'travis/build/appliances/base'
require 'travis/vcs'

module Travis
  module Build
    module Appliances
      class Checkout < Base
        def apply
          Travis::Vcs.checkout(sh, data)
        end

        def apply?
          true
        end
      end
    end
  end
end
