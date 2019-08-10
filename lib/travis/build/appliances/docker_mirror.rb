require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class DockerMirror < Base
        def apply
          sh.raw bash('travis_docker_mirror')
          sh.raw 'travis_docker_mirror'
        end
      end
    end
  end
end
