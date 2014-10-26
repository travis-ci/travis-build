module Travis
  module Build
    class Script
      class NodeJs < Script
        DEFAULTS = {
          :node_js => '0.10'
        }

        def export
          super
          config[:node_js] ||= config[:nodejs] # some old projects use language: nodejs. MK.
          sh.export 'TRAVIS_NODE_VERSION', config[:node_js], echo: false
        end

        def setup
          super
          sh.cmd "nvm install #{node_version}"
          sh.cmd 'npm config set spin false', echo: false
          if npm_should_disable_strict_ssl?
            sh.echo '### Disabling strict SSL ###'
            sh.cmd 'npm conf set strict-ssl false'
          end
          setup_npm_cache if npm_cache_required?
        end

        def announce
          super
          sh.cmd 'node --version'
          sh.cmd 'npm --version'
          sh.cmd 'nvm --version'
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
            sh.cmd 'npm config set registry http://registry.npmjs.org/', echo: false, assert: false
            sh.cmd "npm config set proxy #{data.hosts[:npm_cache]}", echo: false, assert: false
          end
        end

        def cache_slug
          super << '--node-' << config[:node_js].to_s
        end

        private

          def uses_npm?(*args)
            sh.if '-f package.json', *args
          end

          def node_0_6?
            (config[:node_js] || '').to_s.split('.')[0..1] == %w(0 6)
          end

          def npm_should_disable_strict_ssl?
            node_0_6?
          end

          def node_version
            # this check is needed because safe_yaml parses the string 0.10 to 0.1
            config[:node_js] == 0.1 ? "0.10" : config[:node_js]
          end
      end
    end
  end
end
