require 'active_support/core_ext/module/delegation'

module Travis
  module Build
    class Data
      class Env
        delegate :secure_env_enabled?, :pull_request, :config, :build, :job, :repository, to: :data

        attr_reader :data

        def initialize(data)
          @data = data
        end

        def vars
          travis_vars + config_vars
        end

        private

          def travis_vars
            to_vars(
              TRAVIS_PULL_REQUEST:    pull_request || false,
              TRAVIS_SECURE_ENV_VARS: secure_env_vars?,
              TRAVIS_BUILD_ID:        build[:id],
              TRAVIS_BUILD_NUMBER:    build[:number],
              TRAVIS_BUILD_DIR:       '"' + [ BUILD_DIR, repository[:slug] ].join('/') + '"',
              TRAVIS_BUILD_URL:       "https://travis-ci.org/#{repository[:slug]}/builds/#{build[:id]}",
              TRAVIS_JOB_ID:          job[:id],
              TRAVIS_JOB_NUMBER:      job[:number],
              TRAVIS_JOB_URL:         "https://travis-ci.org/#{repository[:slug]}/jobs/#{job[:id]}",
              TRAVIS_BRANCH:          job[:branch],
              TRAVIS_COMMIT:          job[:commit],
              TRAVIS_COMMIT_RANGE:    job[:commit_range],
              TRAVIS_REPO_SLUG:       repository[:slug]
            )
          end

          def extract_config_vars(vars)
            vars = to_vars(Array(vars).compact.reject(&:empty?))
            vars.reject!(&:secure?) unless secure_env_enabled?
            vars
          end

          def config_vars
            extract_config_vars(config[:global_env]) + extract_config_vars(config[:env])
          end

          def to_vars(args)
            args.to_a.map { |args| Var.create(*args) }.flatten
          end

          def secure_env_vars?
            secure_env_enabled? && config_vars.any?(&:secure?)
          end
      end
    end
  end
end
