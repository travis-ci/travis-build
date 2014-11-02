require 'travis/build/appliances/base'
require 'travis/build/script/shared/git'

module Travis
  module Build
    module Appliances
      class Checkout < Base
        def apply
          Script::Git.new(sh, data).checkout
        end
      end
    end
  end
end
