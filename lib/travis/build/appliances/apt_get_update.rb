require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class AptGetUpdate < Base
        def apply
          use_mirror if use_mirror?
          update     if update?
        end

        def apply?
          is_linux?
        end

        private

          def is_linux?
            data[:config][:os] == 'linux'
          end

          def disabled?
            ENV['APT_GET_UPDATE_OPT_IN'] && !update?
          end

          def update?
            if ENV['APT_GET_UPDATE_OPT_IN']
              !!config[:update] || used?
            else
              !config[:update].is_a?(FalseClass) && !used?
            end
          end

          def update
            sh.cmd <<~EOF
              sudo rm -rf /var/lib/apt/lists/*
              sudo apt-get update #{'-qq  >/dev/null 2>&1' unless debug?}
            EOF
          end

          def used?
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
            apt_config || {}
          end

          def apt_config
            (data[:config][:addons] && data[:config][:addons][:apt]) || data[:config][:apt]
          end
      end
    end
  end
end

