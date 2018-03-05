require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class WaitForNetwork < Base
        def apply
          sh.raw 'travis_wait_for_network "${TRAVIS_JOB_ID}" "${TRAVIS_REPO_SLUG}"'
        end
      end
    end
  end
end

