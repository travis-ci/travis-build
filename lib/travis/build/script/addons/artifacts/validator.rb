module Travis
  module Build
    class Script
      module Addons
        class Artifacts
          class Validator
            MSGS = {
              config_missing: 'The configuration for artifacts support is missing: %s',
              pull_request: 'Artifacts support disabled for pull requests',
              branch_disabled: 'Artifacts support disabled: the current branch is not enabled as per configuration (%s)'
            }

            attr_reader :data, :config, :errors

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
                private_methods.grep(/^validate_/).each { |method| send(method) }
              end

              def validate_config
                missing = [:key, :secret, :bucket] - config.keys
                return true if missing.empty?
                errors << MSGS[:config_missing] % missing.map(&:inspect).join(', ')
              end

              def validate_push_request
                return true if push_request?
                errors << MSGS[:pull_request]
              end

              def validate_branch_runnable
                return true if no_branch_configured? || branch_enabled?
                errors << MSGS[:branch_disabled] % data.branch
              end

              def push_request?
                !data.pull_request
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
          end
        end
      end
    end
  end
end
