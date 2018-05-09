require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class AptGetUpdate < Base
        def apply
          sh.cmd <<-EOF
            sudo rm -rf /var/lib/apt/lists/*
            sudo apt-get update #{'-qq  >/dev/null 2>&1' unless debug?}
          EOF
        end

        private

          def debug?
            Travis::Rollout.matches?(:debug_apt, repo: slug)
          end

          def slug
            data.repository[:slug].to_s
          end
      end
    end
  end
end

