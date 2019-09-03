require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class Validate < Base
        MSGS = {
          not_found:    ['Could not find .travis.yml, using standard configuration.', ansi: :red],
          server_error: ['Could not fetch .travis.yml from GitHub.', ansi: :red]
        }

        attr_reader :msgs, :result

        def initialize(*)
          super
          @result = true
          @msgs = []
        end

        def apply
          validate_config
          msgs.each { |msg| sh.echo *msg }
          sh.terminate unless result
          result
        end

        def apply?
          true
        end

        def time?
          false
        end

        private

          def validate_config
            msg = MSGS[config_status]
            msgs << msg if msg
            @result = false if config_status == :server_error
          end

          def config_status
            status = config[:".result"]
            status.to_sym if status
          end
      end
    end
  end
end
