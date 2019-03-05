require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class AptGetUpdate < Base
        def apply
          use_mirror
          use_proxy
          update if update?
        end

        def apply?
          true
        end

        def config
          apt_config || {}
        end

        private

          def update?
            if ENV['APT_GET_UPDATE_OPT_IN']
              !!config[:update] || used?
            else
              !config[:update].is_a?(FalseClass) && !used?
            end
          end

          def update
            sh.cmd "travis_apt_get_update#{debug? ? ' debug' : ''}", retry: true
          end

          def used?
            %i(before_install install before_script script before_cache).any? do |stage|
              Array(data[:config][stage]).flatten.compact.any? do |script|
                script.to_s =~ /apt-get .*install/
              end
            end
          end

          def use_mirror
            define_mirrors_by_infrastructure
            sh.raw bash('travis_munge_apt_sources')
            sh.cmd 'travis_munge_apt_sources'
          end

          def use_proxy
            sh.raw bash('travis_setup_apt_proxy')
            sh.cmd 'travis_setup_apt_proxy'
          end

          def define_mirrors_by_infrastructure
            sh.raw 'declare -a _TRAVIS_APT_MIRRORS_BY_INFRASTRUCTURE'
            mirrors.each do |infra, url|
              sh.raw %{_TRAVIS_APT_MIRRORS_BY_INFRASTRUCTURE+=(#{infra}::#{url})}.output_safe
            end
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

          def mirrors
            (Travis::Build.config[:apt_mirrors] || {}).to_hash
          end

          def apt_config
            (data[:config][:addons] && data[:config][:addons][:apt]) || data[:config][:apt]
          end
      end
    end
  end
end
