require_relative 'manager/base'
require_relative 'manager/nvm'
require_relative 'manager/nvs'

module Travis
  module Build
    class NodeJs
      class Manager
        def self.nvm(node_js)
          Manager::Nvm.new(node_js)
        end

        def self.nvs(node_js)
          Manager::Nvs.new(node_js)
        end
      end
    end
  end
end
