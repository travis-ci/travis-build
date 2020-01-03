require 'travis/build/appliances/base'
require 'travis/build/git'
require 'travis/rollout'

module Travis
  module Build
    module Appliances
      class SetupFilter < Base
        class Rollout < Struct.new(:data)
          def matches?
            Travis::Rollout.matches?(:redirect_io, uid: repo_id, owner: owner_login) && !blocklist.include?(owner_login)
          end

          def repo_id
            data.repository[:vcs_id] || data.repository[:github_id]
          end

          def repo_slug
            data.repository[:slug].to_s
          end

          def owner_login
            repo_slug.split('/').first
          end

          def blocklist
            ENV["ROLLOUT_REDIRECT_IO_OWNERS_BLOCKLIST"].to_s.split(',')
          end
        end

        ENABLED = true

        HOST = 'build.travis-ci.com'

        MSGS = {
          filter: 'Using filter strategy %p for repo %s on job id=%s number=%s'
        }

        SH = {
          curl: %(
              curl -sf -o ~/filter.rb %{url}
              if [ $? -ne 0 ]; then
                echo "Download from %{url} failed. Trying %{fallback_url} ..."
                curl -sf -o ~/filter.rb %{fallback_url}
              fi
          ),
          pty: %(
            if [[ -z "$TRAVIS_FILTERED" ]]; then
              export TRAVIS_FILTERED=pty
              %{curl}
              %{exports}
              exec ruby ~/filter.rb "/usr/bin/env TERM=xterm /bin/bash --login ${TRAVIS_HOME}/build.sh" %{args}
            fi
          ),
          redirect_io: %(
            export TRAVIS_FILTERED=redirect_io
            exec 9>&1 1> >(
              %{curl}
              %{exports}
              ruby ~/filter.rb %{args}
            ) 2>&1
          )
        }

        def apply?
          sh.echo 'Secret environment variables are not obfuscated on Windows, please refer to our documentation: https://docs.travis-ci.com/user/best-practices-security', ansi: 'yellow' if windows?
          enabled? and secrets.any? and !windows?
        end

        def apply
          info :filter, strategy, data.repository[:slug].to_s, data.job[:id], data.job[:number]
          puts code if ENV['ROLLOUT_DEBUG']
          sh.raw code.output_safe
        end

        private

          def code
            data = { exports: exports, args: args, url: url, fallback_url: url(HOST) }
            curl = SH[:curl] % data
            SH[strategy] % data.merge(curl: curl)
          end

          def enabled?
            config[:filter_secrets].nil? ? ENABLED : config[:filter_secrets]
          end

          def strategy
            @strategy ||= Rollout.new(data).matches? ? :redirect_io : :pty
          end

          def url(host = nil)
            host ||= app_host || HOST
            url = "https://#{host}/filter/#{strategy}.rb"
            Shellwords.escape(url)
          end

          def args
            secrets.size.times.map { |ix| "-e \"SECRET_#{ix}\"" }.join(" ")
          end

          def exports
            values = secrets.map { |value| Shellwords.escape(value) }
            values = values.map.with_index { |value, ix| "export SECRET_#{ix}=#{value}" }
            values.join(' ')
          end

          def secrets
            @secrets ||= env.groups.flat_map(&:vars).select(&:secure?).map(&:value)
          end

          def env
            @env ||= Build::Env.new(data)
          end

          def info(msg, *args)
            Travis::Build.logger.info(MSGS[msg] % args)
          end
      end
    end
  end
end
