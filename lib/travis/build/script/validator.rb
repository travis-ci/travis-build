module Travis
  module Build
    class Script
        class Validator
          MSGS = {
            not_found:    ['Could not find .travis.yml, using standard configuration.', ansi: :red],
            server_error: ['Could not fetch .travis.yml from GitHub.', ansi: :red]
          }

          attr_reader :sh, :config, :result, :msgs

          def initialize(sh, config)
            @sh = sh
            @config = config
            @result = true
            @msgs = []
          end

          def run
            validate_config
            msgs.each { |msg| sh.echo *msg }
            sh.terminate unless result
            result
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
