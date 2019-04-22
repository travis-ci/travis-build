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
            install_version version
            use_version version
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
