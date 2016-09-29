require 'shellwords'
require 'travis/build/env/base'

module Travis
  module Build
    class Env
      class Builtin < Base
        def_delegators :data, :build, :job, :repository, :pull_request

        def vars
          env_vars.map do |key, value|
            value = value.to_s.shellescape
            value = [BUILD_DIR, value].join('/') if key == :TRAVIS_BUILD_DIR
            Var.new(key, value, type: :builtin)
          end
        end

        private

          def env_vars
            {
              TRAVIS:                 true,
              CI:                     true,
              CONTINUOUS_INTEGRATION: true,
              HAS_JOSH_K_SEAL_OF_APPROVAL: true,
              TRAVIS_EVENT_TYPE:      build[:event_type],
              TRAVIS_PULL_REQUEST:    pull_request || false,
              TRAVIS_SECURE_ENV_VARS: env.secure_env_vars? || false,
              TRAVIS_BUILD_ID:        build[:id],
              TRAVIS_BUILD_NUMBER:    build[:number],
              TRAVIS_BUILD_DIR:       repository[:slug],
              TRAVIS_JOB_ID:          job[:id],
              TRAVIS_JOB_NUMBER:      job[:number],
              TRAVIS_BRANCH:          job[:branch],
              TRAVIS_COMMIT:          job[:commit],
              TRAVIS_COMMIT_RANGE:    job[:commit_range],
              TRAVIS_REPO_SLUG:       repository[:slug],
              TRAVIS_OS_NAME:         config[:os],
              TRAVIS_LANGUAGE:        config[:language],
              TRAVIS_TAG:             job[:tag],
              TRAVIS_PULL_REQUEST_BRANCH: job[:pull_request_head_branch],
              TRAVIS_PULL_REQUEST_SHA: job[:pull_request_head_sha],
            }
          end
      end
    end
  end
end
