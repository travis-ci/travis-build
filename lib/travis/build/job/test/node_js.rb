require 'active_support/memoizable'

module Travis
  class Build
    module Job
      class Test
        class NodeJs < Test
          class Config < Hashr
            define :node_js => '0.4'
            def nodejs
              # some old projects use language: nodejs. MK.
              self[:node_js]
            end
          end

          extend ActiveSupport::Memoizable

          def setup
            shell.execute("nvm use #{config.node_js}")
          end
          assert :setup

          def install
            "npm install #{config.npm_args}".strip if uses_npm?
          end

          def script
            uses_npm? ? 'npm test' : 'make test'
          end

          protected

            def uses_npm?
              shell.file_exists?('package.json')
            end
            memoize :uses_npm?
        end
      end
    end
  end
end
