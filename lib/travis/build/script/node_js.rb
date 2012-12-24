module Travis
  module Build
    class Script
      class NodeJs < Script
        DEFAULTS = {
          :node_js => '0.4'
        }

        def export
          super
          config[:node_js] ||= config[:nodejs] # some old projects use language: nodejs. MK.
          set 'TRAVIS_NODE_VERSION', config[:node_js]
        end

        def setup
          super
          cmd "nvm use #{config[:node_js]}"
        end

        def announce
          super
          cmd 'node --version'
          cmd 'npm --version'
        end

        def install
          uses_npm? "npm install #{config[:npm_args]}"
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

