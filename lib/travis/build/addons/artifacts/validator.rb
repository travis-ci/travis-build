module Travis
  module Build
    class Addons
      class Artifacts < Base
        class Validator
          MSGS = {
            pull_request: 'Artifacts support disabled for pull requests',
            branch_disabled: 'Artifacts support disabled: the current branch is not enabled as per configuration (%s)'
          }

          attr_reader :data, :errors

          def initialize(data, config)
            @data = data
            @config = config
            @errors = []
          end

          def valid?
            validate
            errors.empty?
          end

          private

            def validate
              validate_push_request
              validate_branch
            end

            def validate_push_request
              error :pull_request if pull_request?
            end

            def validate_branch
              error :branch_disabled, data.branch unless branch_runnable?
            end

            def pull_request?
              data.pull_request
            end

            def branch_runnable?
              no_branch_configured? || branch_enabled?
            end

            def no_branch_configured?
              branch.nil?
            end

            def branch_enabled?
              [branch].flatten.include?(data.branch)
            end

            def branch
              config[:branch]
            end

            def error(type, data = nil)
              msg = MSGS[type]
              msg = msg % data if data
              errors << msg
            end

            def config
              # @config is assigned a hash with Symbols as keys,
              # but when we access it via attr_reader, the keys are
              # somehow strings.
              # This causes validator to be ineffctive.
              # See https://github.com/travis-ci/artifacts/issues/70
              @config.deep_symbolize_keys
            end
        end
      end
    end
  end
end
