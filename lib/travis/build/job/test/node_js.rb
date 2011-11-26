require 'active_support/memoizable'

module Travis
  class Build
    module Job
      class Test
        class NodeJs < Test
          class Config < Hashr
            define :node_js => '0.4'
            def nodejs; self[:node_js]; end # TODO legacy
          end

          extend ActiveSupport::Memoizable

          def setup
            shell.execute("nvm use #{config.node_js}")
          end
          assert :setup

          def install
            "npm install #{config.npm_args}".strip if npm?
          end

          def script
            npm? ? 'npm test' : 'make test'
          end

          protected

            def npm?
              shell.file_exists?('package.json')
            end
            memoize :npm?
        end
      end
    end
  end
end
