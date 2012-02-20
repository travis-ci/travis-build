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

          def setup
            super

            setup_node
            announce_node
          end

          def install
            "npm install #{config.npm_args}".strip if uses_npm?
          end

          def script
            uses_npm? ? 'npm test' : 'make test'
          end

          protected

          def uses_npm?
            @uses_npm ||= shell.file_exists?('package.json')
          end

          def setup_node
            shell.execute("nvm use #{config.node_js}")
          end
          assert :setup_node

          def announce_node
            shell.execute("node --version")
            shell.execute("npm --version")
          end

          def export_environment_variables
            shell.export_line("TRAVIS_NODE_VERSION=#{config.node_js}")
          end
        end
      end
    end
  end
end
