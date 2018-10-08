require_relative 'base'
module Travis
  module Build
    class NodeJs
      class Manager
        class Nvs < Base
          def initialize(node_js)
            super

          end

          def setup

          end

          def update

          end

          def install
            sh.fold "nvs" do
              sh.echo "Using NVS for managing Node.js versions on Windows (BETA)", ansi: :yellow
              install_version version
              use_version version
            end
          end

          def show_version
            sh.cmd 'nvs --version'
          end

          def install_version(version)
            sh.cmd "nvs add #{version}"
          end

          def use_version(version)
            sh.cmd "nvs use #{version}"
          end
        end
      end
    end
  end
end
