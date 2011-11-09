require 'active_support/memoizable'

module Travis
  class Build
    module Job
      class Test
        class Nodejs < Test
          class Config < Hashr
            define :node_js => '0.4.12'
            def nodejs; self[:node_js]; end # TODO legacy
          end

          extend ActiveSupport::Memoizable

          def setup
            setup_nvm
          end

          def install
            install_npm if npm?
          end

          protected

            def setup_nvm
              shell.execute("nvm use #{config.node_js}")
            end
            assert :setup_nvm

            def npm?
              shell.file_exists?('package.json')
            end
            memoize :npm?

            def install_npm
              shell.execute("npm install #{config.npm_args}".strip, :timeout => :install)
            end
            assert :install_npm

            def script
              if config.script?
                config.script
              elsif npm?
                'npm test'
              else
                'make test'
              end
            end
        end
      end
    end
  end
end
