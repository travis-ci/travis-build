require 'travis/build/appliances/base'
require 'travis/rollout'

module Travis
  module Build
    module Appliances
      class SetX < Base
        def apply?
          enabled?
        end

        def apply
          sh.raw 'set -x'
        end

        private

          def enabled?
            Travis::Rollout.matches?(:set_x, repo: slug)
          end

          def slug
            data.repository[:slug].to_s
          end
      end
    end
  end
end
