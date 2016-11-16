require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class RmDockerprojectAptSource < Base
        MSG = "Due to infrastructure issues with apt.dockerproject.org we're disabling the apt repository for now. " \
              "If you're relying on being able to change your Docker version via \\`apt-get\\`, that will not work right now. " \
              "We're sorry for the trouble, please follow https://github.com/travis-ci/travis-ci/issues/6881 for updates on when the apt repository infrastructure is fixed"
        CMD = 'sudo rm -f /etc/apt/sources.list.d/docker.list'

        def apply
          sh.if "\"$(lsb_release -cs)\" = trusty" do
            sh.echo MSG, ansi: :yellow
            sh.cmd CMD
          end
        end

        def apply?
          ! data.disable_sudo?
        end
      end
    end
  end
end
