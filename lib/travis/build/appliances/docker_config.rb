require 'shellwords'
require 'travis/build/appliances/base'
require 'travis/build/helpers/template'

module Travis
  module Build
    module Appliances
      class DockerConfig < Base
        include Template

        def apply
          sh.fold "Docker config" do
            sh.raw "export BUILDKIT_PROGRESS=#{buildkit_progress}"
          end
        end

        def buildkit_progress
          ENV['TRAVIS_BUILD_DOCKER_BUILDKIT_PROGRESS'] || 'plain'
        end
      end
    end
  end
end
