require 'shellwords'
require 'travis/build/env/base'

module Travis
  module Build
    class Env
      class Builtin < Base
        def_delegators :data, :build, :job, :repository, :pull_request

        def vars
          to_vars(env_vars, type: :builtin)
        end

        private

          def env_vars
            {
              TRAVIS:                 true,
              CI:                     true,
              CONTINUOUS_INTEGRATION: true,

              TRAVIS_OS_NAME:         config[:os],
              TRAVIS_LANGUAGE:        config[:language],
              TRAVIS_REPO_SLUG:       slug.shellescape,
              TRAVIS_BUILD_ID:        build[:id],
              TRAVIS_BUILD_NUMBER:    build[:number],
              TRAVIS_BUILD_DIR:       [BUILD_DIR, slug.shellescape].join('/'),
              TRAVIS_JOB_ID:          job[:id],
              TRAVIS_JOB_NUMBER:      job[:number],
              TRAVIS_BRANCH:          branch.shellescape,
              TRAVIS_COMMIT:          job[:commit],

              TRAVIS_COMMIT_RANGE:    job[:commit_range],
              TRAVIS_TAG:             job[:tag],
              TRAVIS_PULL_REQUEST:    pull_request || false,
              TRAVIS_SECURE_ENV_VARS: secure_env_vars? || false
            }
          end

          def slug
            repository[:slug] || ''
          end

          def branch
            job[:branch] || ''
          end

          def secure_env_vars?
            env.secure_env_vars?
          end
      end
    end
  end
end
