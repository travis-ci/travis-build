module Travis
  module Build
    class Script
      class NodeJs < Script
        DEFAULTS = {
          :node_js => '0.4'
        }

        def export
          super
          data[:node_js] ||= data[:nodejs] # some old projects use language: nodejs. MK.
          set 'TRAVIS_NODE_VERSION', data[:node_js]
        end

        def setup
          super
          cmd "nvm use #{data[:node_js]}"
        end

        def announce
          super
          cmd 'node --version'
          cmd 'npm --version'
        end

        def install
          uses_npm? "npm install #{data[:npm_args]}"
        end

        def script
          uses_npm? then: 'npm test', else: 'make test'
        end

        private

          def uses_npm?(*args)
            sh_if '-f package.json', *args
          end
      end
    end
  end
end

