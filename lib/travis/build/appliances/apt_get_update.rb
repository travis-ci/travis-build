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
            !!mirror && rollout?(:apt_get_mirror_ubuntu, uid: repo_id, owner: repo_owner)
          end

          def use_mirror
            sh.cmd "sudo sed -i 's_http://archive.ubuntu.com/ubuntu/_#{mirror.dup.untaint}_' /etc/apt/sources.list"
          end

          def mirror
            ENV['APT_GET_MIRROR_UBUNTU']
          end

          def debug?
            rollout?(:debug_apt, repo: repo_slug)
          end

          def rollout?(*args)
            Travis::Rollout.matches?(*args)
          end

          def repo_id
            data.repository[:id]
          end

          def repo_slug
            data.repository[:slug].to_s
          end

          def repo_owner
            repo_slug.split('/').first
          end
      end
    end
  end
end

