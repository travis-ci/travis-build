require 'shellwords'
require 'travis/build/env/base'

module Travis
  module Build
    class Env
      class Builtin < Base
        def_delegators :data, :build, :job, :repository, :pull_request

        RUNTIME_VARS = %i(
          TRAVIS_COMMIT_MESSAGE
        )

        def vars
          env_vars.map do |key, value|
            value = value.to_s
            value = value.shellescape unless RUNTIME_VARS.include? key
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
              PAGER:                  'cat',
              HAS_JOSH_K_SEAL_OF_APPROVAL: true,
              TRAVIS_ALLOW_FAILURE:   job[:allow_failure],
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
              TRAVIS_COMMIT_MESSAGE: '$(git log --format=%B -n 1 | head -c 32768)',
              TRAVIS_COMMIT_RANGE:    job[:commit_range],
              TRAVIS_REPO_SLUG:       repository[:slug],
              TRAVIS_OS_NAME:         config[:os],
              TRAVIS_LANGUAGE:        config[:language],
              TRAVIS_TAG:             job[:tag],
              TRAVIS_SUDO:            (!!!data[:paranoid]).to_s,
              TRAVIS_PULL_REQUEST_BRANCH: job[:pull_request_head_branch],
              TRAVIS_PULL_REQUEST_SHA: job[:pull_request_head_sha],
              TRAVIS_PULL_REQUEST_SLUG: job[:pull_request_head_slug],
            }
          end
      end
    end
  end
end
