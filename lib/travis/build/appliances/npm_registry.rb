require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class NpmRegistry < Base
        def apply
          if data[:npm_registry]
            sh.fold "npm_registry" do
              sh.export 'NPM_CONFIG_REGISTRY', data[:npm_registry], echo: true
            end
          end
        end
      end
    end
  end
end
