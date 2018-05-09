require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class AptGetUpdate < Base
        def apply
          use_mirror if use_mirror?
          apt_get_update if apt_get_update?
        end

        private

          def apt_get_update?
            if ENV['APT_GET_UPDATE_OPT_IN']
              !!config[:update] && !uses_apt_get?
            else
              !config[:update].is_a?(FalseClass) && !uses_apt_get?
            end
          end

          def apt_get_update
            sh.cmd <<-EOF
              sudo rm -rf /var/lib/apt/lists/*
              sudo apt-get update #{'-qq  >/dev/null 2>&1' unless debug?}
            EOF
          end

          def uses_apt_get?
            %i(before_install install before_script script before_cache).any? do |stage|
              Array(data[:config][stage]).flatten.compact.any? do |script|
                script.to_s =~ /apt-get .*install/
              end
            end
          end

          def use_mirror?
            !!mirror && rollout?(:apt_get_mirror_ubuntu, uid: repo_id, owner: repo_owner)
          end

          def use_mirror
            sh.cmd "sudo sed -i -e 's|http://.*\.ubuntu\.com/ubuntu/|#{mirror.dup.untaint}|' /etc/apt/sources.list"
          end

          def mirror
            ENV['APT_GET_MIRROR_UBUNTU']
          end

          def debug?
            rollout?(:debug_apt, repo: repo_slug, owner: repo_owner)
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

          def config
            data[:config][:apt] || {}
          end
      end
    end
  end
end

