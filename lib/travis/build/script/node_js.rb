module Travis
  module Build
    class Script
      class NodeJs < Script
        DEFAULTS = {
          :node_js => '0.10'
        }

        def cache_slug
          super << "--node-" << config[:node_js].to_s
        end

        def export
          super
          config[:node_js] ||= config[:nodejs] # some old projects use language: nodejs. MK.
          set 'TRAVIS_NODE_VERSION', config[:node_js], echo: false
        end

        def setup
          super
          cmd "nvm use #{config[:node_js]}"
          setup_npm_cache if npm_cache_required?
        end

        def announce
          super
          cmd 'node --version'
          cmd 'npm --version'
        end

        def install
          uses_npm? then: "npm install #{config[:npm_args]}", fold: 'install', retry: true
        end

        def script
          uses_npm? then: 'npm test', else: 'make test'
        end

        def npm_cache_required?
          Array(config[:cache]).include?('npm')
        end

        def setup_npm_cache
          if data.hosts && data.hosts[:npm_cache]
            cmd 'npm config set registry http://registry.npmjs.org/', echo: false, assert: false
            cmd "npm config set proxy #{data.hosts[:npm_cache]}", echo: false, assert: false
          end
        end

        private

          def uses_npm?(*args)
            self.if '-f package.json', *args
          end
      end
    end
  end
end

