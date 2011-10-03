module Travis
  module Build
    module Job
      class Test
        class Nodejs < Test
          class Config < Hashr
            define :nodejs_version => '0.4.11'
          end

          def setup
            super
            setup_nvm
          end

          def install
            install_npm if package?
          end

          protected

            def setup_nvm
              shell.execute("nvm use v#{config.nodejs_version}")
            end

            def package?
              shell.file_exists?('package.json')
            end

            def install_npm
              shell.execute("npm install #{config.npm_args}".strip, :timeout => :install_deps)
            end
            assert :install_npm

            def script
              if config.script?
                config.script
              elsif package?
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
