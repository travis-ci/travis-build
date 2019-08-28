require 'travis/rollout'
require 'travis/build/appliances/base'
require 'travis/build/git'
require 'travis/build/perforce'

module Travis
  module Build
    module Appliances
      class Checkout < Base
        def apply
          strategy.new(sh, data).checkout
        end

        def apply?
          true
        end

        def strategy
          perforce? ? Perforce : Git
        end

        def perforce?
          Travis::Rollout.matches?(:perforce, owner: owner)
        end

        def owner
          data.slug.split('/').first
        end
      end
    end
  end
end
