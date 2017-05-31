require 'travis/build/appliances/base'
require 'travis/build/git'
require 'travis/rollout'

module Travis
  module Build
    module Appliances
      class SetupFilter < Base
        class Rollout < Struct.new(:data)
          def matches?
            Travis::Rollout.matches?(:redirect_io, uid: repo_id, owner: owner_login)
          end

          def repo_id
            data.repository[:github_id]
          end

          def repo_slug
            data.repository[:slug].to_s
          end

          def owner_login
            repo_slug.split('/').first
          end
        end

        DEFAULT_SETTING = true

        SH = {
          pty: %(
            if [[ -z "$TRAVIS_FILTERED" ]]; then
              export TRAVIS_FILTERED=1
              curl -sf -o ~/filter.rb %s
              %s
              exec ruby ~/filter.rb "/usr/bin/env TERM=xterm /bin/bash --login $HOME/build.sh" %s
            fi
          ),
          redirect_io: %(
            exec > >(
              curl -sf -o ~/filter.rb %s
              %s
              ruby ~/filter.rb %s
            ) 2>&1
          )
        }

        MSGS = {
          filter: 'Using filter strategy %p for repo %s on job id=%s number=%s'
        }

        def apply?
          enabled? and secrets.any?
        end

        def apply
          info :filter, strategy, data.repository[:slug].to_s, data.job[:id], data.job[:number]
          puts SH[strategy] % [Shellwords.escape(download_url), exports, args] if ENV['ROLLOUT_DEBUG']
          sh.raw SH[strategy] % [Shellwords.escape(download_url), exports, args]
        end

        private

          def enabled?
            config[:filter_secrets].nil? ? DEFAULT_SETTING : config[:filter_secrets]
          end

          def strategy
            @strategy ||= Rollout.new(data).matches? ? :redirect_io : :pty
          end

          def download_url
            "https://#{host}/filter#{'_pty' if strategy == :pty}.rb".untaint
          end

          def args
            secrets.size.times.map { |ix| "-e \"SECRET_#{ix}\"" }.join(" ")
          end

          def exports
            values = secrets.map(&:untaint)
            values = values.map { |value| Shellwords.escape(value) }
            values = values.map.with_index { |value, ix| "export SECRET_#{ix}=#{value}" }
            values.join(' ')
          end

          def secrets
            @secrets ||= env.groups.flat_map(&:vars).select(&:secure?).map(&:value)
          end

          def env
            @env ||= Build::Env.new(data)
          end

          def host
            app_host.empty? ? 'build.travis-ci.com' : app_host
          end

          def info(msg, *args)
            Travis::Build.logger.info(MSGS[msg] % args)
          end
      end
    end
  end
end
