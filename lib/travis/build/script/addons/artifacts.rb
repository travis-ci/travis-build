module Travis
  module Build
    class Script
      module Addons
        class Artifacts
          attr_accessor :script, :config

          def initialize(script, config)
            @script = script
            @config = config
          end

          def after_script
            return if config.empty?
            script.if(want) { run }
          end

          private

          def want
            "($TRAVIS_PULL_REQUEST = false) && ($TRAVIS_BRANCH = #{branch})"
          end

          def run
            options = config.delete(:options)
            script.fold('artifacts.0') { install }
            script.fold('artifacts.0') { configure_env }
            script.fold('artifacts.1') do
              script.set('PATH', '$HOME/bin:$PATH', echo: false, assert: false)
              script.cmd(
                "artifacts upload #{options}",
                echo: false,
                assert: false
              )
            end
          end

          def branch
            config[:branch] || 'master'
          end

          def install
            script.cmd(
              'artifacts -v || ' \
              'curl -sL https://raw.githubusercontent.com/meatballhat/artifacts/master/install | bash',
              echo: false, assert: false
            )
          end

          def configure_env
            config.each { |key, value| setenv(key, value) }
          end

          def setenv(key, value, prefix = 'ARTIFACTS_')
            value = value.map(&:to_s).join(';') if value.respond_to?(:each)
            script.set(
              "#{prefix}#{key.upcase}", "#{value}", echo: false, assert: false
            )
          end
        end
      end
    end
  end
end
