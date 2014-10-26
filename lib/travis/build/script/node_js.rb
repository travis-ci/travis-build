module Travis
  module Build
    class Script
      class NodeJs < Script
        DEFAULTS = {
          :node_js => '0.10'
        }

        def export
          super
          sh.export 'TRAVIS_NODE_VERSION', version, echo: false
        end

        def setup
          super
          sh.cmd "nvm install #{version}"
          sh.cmd 'npm config set spin false', echo: false
          npm_disable_strict_ssl unless npm_strict_ssl?
          setup_npm_cache if use_npm_cache?
        end

        def announce
          super
          sh.cmd 'node --version'
          sh.cmd 'npm --version'
          sh.cmd 'nvm --version'
        end

        def install
          sh.if '-f package.json' do
            sh.cmd "npm install #{config[:npm_args]}", retry: true, fold: 'install'
          end
        end

        def script
          sh.if '-f package.json' do
            sh.cmd 'npm test'
          end
          sh.else do
            sh.cmd 'make test'
          end
        end

        def cache_slug
          super << '--node-' << version
        end

        private

          def version
            # TODO deprecate :nodejs
            version = config[:node_js] || config[:nodejs] # some old projects use language: nodejs. MK.
            version == 0.1 ? '0.10' : version
          end

          def npm_disable_strict_ssl
            sh.echo '### Disabling strict SSL ###', ansi: :red
            sh.cmd 'npm conf set strict-ssl false', timing: false
          end

          def npm_strict_ssl?
            !node_0_6?
          end

          def node_0_6?
            (config[:node_js] || '').to_s.split('.')[0..1] == %w(0 6)
          end

          def use_npm_cache?
            Array(config[:cache]).include?('npm')
          end

          def setup_npm_cache
            if data.hosts && data.hosts[:npm_cache]
              sh.cmd 'npm config set registry http://registry.npmjs.org/', timing: false
              sh.cmd "npm config set proxy #{data.hosts[:npm_cache]}", timing: false
            end
          end
      end
    end
  end
end
