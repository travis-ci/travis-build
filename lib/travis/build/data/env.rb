require 'active_support/core_ext/module/delegation'

module Travis
  module Build
    class Data
      class Env
        delegate :pull_request, :config, :build, :job, :repository, to: :data

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
              TRAVIS_JOB_ID:          job[:id],
              TRAVIS_JOB_NUMBER:      job[:number],
              TRAVIS_BRANCH:          job[:branch],
              TRAVIS_COMMIT:          job[:commit],
              TRAVIS_COMMIT_RANGE:    job[:commit_range],
              TRAVIS_REPO_SLUG:       repository[:slug]
            )
          end

          def config_vars
            vars = to_vars(Array(config[:env]).compact.reject(&:empty?))
            vars.reject!(&:secure?) if pull_request
            vars
          end

          def to_vars(args)
            args.to_a.map { |args| Var.create(*args) }.flatten
          end

          def secure_env_vars?
            !pull_request && config_vars.any?(&:secure?)
          end
      end
    end
  end
end
