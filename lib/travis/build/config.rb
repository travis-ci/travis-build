require 'core_ext/hash/deep_merge'
require 'core_ext/hash/deep_symbolize_keys'

module Travis
  module Build
    class Config
      DEFAULTS = {
        timeouts: {
          git_clone:      300,
          git_fetch_ref:  300,
          git_submodules: 300,
          start_service:  60,
          before_install: 300,
          install:        600,
          before_script:  600,
          script:         1500,
          after_success:  300,
          after_failure:  300,
          after_script:   300
        }
      }

      attr_reader :config

      def initialize(config, defaults = {})
        config = config.deep_symbolize_keys
        defaults = defaults.deep_symbolize_keys
        @config = DEFAULTS.deep_merge(defaults.deep_merge(config))
      end

      def [](key)
        config[:config][key]
      end

      def urls
        {
          # TODO this could point to https://api.travis-ci.com/jobs/:id/log and /jobs/:id/state or something
          logs:  'http://requestb.in/18ygqfo1',
          state: 'http://requestb.in/12g6u3e1'
        }
      end

      def timeout?(type)
        !!config[:timeouts][type]
      end

      def timeout(type)
        config[:timeouts][type] || raise("Unknown timeout: #{type}")
      end

      def env
        @env ||= travis_env.merge(split_env(config[:config][:env]))
      end

      def pull_request?
        !!job[:pull_request]
      end

      def source_url
        repository[:source_url]
      end

      def slug
        repository[:slug]
      end

      def commit
        job[:commit]
      end

      def ref
        job[:ref]
      end

      private

        def travis_env
          {
            TRAVIS_PULL_REQUEST:    pull_request?,
            TRAVIS_SECURE_ENV_VARS: secure_env_vars?,
            TRAVIS_BUILD_ID:        source[:id],
            TRAVIS_BUILD_NUMBER:    source[:number],
            TRAVIS_JOB_ID:          job[:id],
            TRAVIS_JOB_NUMBER:      job[:number],
            TRAVIS_BRANCH:          job[:branch],
            TRAVIS_COMMIT_RANGE:    job[:commit_range],
            TRAVIS_COMMIT:          job[:commit]
          }
        end

        def split_env(env)
          env = Array(env).compact.reject(&:empty?)
          Hash[*env.map { |line| line.split('=') }.flatten]
        end

        # TODO is this correct at all??
        def secure_env_vars?
          !pull_request? && Array(config[:env]).any? { |line| line.to_s =~ /^SECURE / }
        end

        def job
          config[:job] || {}
        end

        def source
          config[:source] || {}
        end

        def repository
          config[:repository] || {}
        end
    end
  end
end
