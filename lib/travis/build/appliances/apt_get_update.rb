require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class AptGetUpdate < Base
        def apply
          use_mirror if use_mirror?
          apt_get_update
        end

        private

          def apt_get_update
            sh.cmd <<-EOF
              sudo rm -rf /var/lib/apt/lists/*
              sudo apt-get update #{'-qq  >/dev/null 2>&1' unless debug?}
            EOF
          end

          def use_mirror?
            !!mirror
          end

          def use_mirror
            sh.cmd "sudo sed -i 's_http://archive.ubuntu.com/ubuntu/_#{mirror.dup.untaint}_' /etc/apt/sources.list"
          end

          def mirror
            ENV['APT_GET_MIRROR_UBUNTU']
          end

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

