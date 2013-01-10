require 'core_ext/hash/deep_merge'
require 'core_ext/hash/deep_symbolize_keys'

# actually, the worker payload can be cleaned up a lot ...

module Travis
  module Build
    class Data
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

      attr_reader :data

      def initialize(data, defaults = {})
        data = data.deep_symbolize_keys
        defaults = defaults.deep_symbolize_keys
        @data = DEFAULTS.deep_merge(defaults.deep_merge(data))
      end

      def urls
        data[:urls] || {}
      end

      def timeout?(type)
        !!data[:timeouts][type]
      end

      def timeout(type)
        data[:timeouts][type] || raise("Unknown timeout: #{type}")
      end

      def config
        data[:config]
      end

      def env
        @env ||= travis_env.merge(split_env(config[:env]))
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
            TRAVIS_BUILD_ID:        build[:id],
            TRAVIS_BUILD_NUMBER:    build[:number],
            TRAVIS_JOB_ID:          job[:id],
            TRAVIS_JOB_NUMBER:      job[:number],
            TRAVIS_BRANCH:          job[:branch],
            TRAVIS_COMMIT:          job[:commit],
            TRAVIS_COMMIT_RANGE:    job[:commit_range]
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
          data[:job] || {}
        end

        def build
          data[:source] || data[:build] || {} # TODO standarize the payload on :build
        end

        def repository
          data[:repository] || {}
        end
    end
  end
end
