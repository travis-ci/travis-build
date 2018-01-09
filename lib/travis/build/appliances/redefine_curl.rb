require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class RedefineCurl < Base
        def apply
          sh.raw <<-EOF
function curl() {
  command curl --retry 2 -sS "$@"
}
          EOF
        end
      end
    end
  end
end
