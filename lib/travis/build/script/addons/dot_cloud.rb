require 'travis/build/script/addons/deploy'

module Travis
  module Build
    class Script
      module Addons
        class DotCloud < Deploy
          private
            def tools
              `pip install dotcloud`
            end

            def deploy
              silent { `echo #{option(:api_key)} | dotcloud setup --api-key` }
              `dotcloud push #{app}`
            end

            def run(cmd)
              service = config[:instance] || config[:service] || 'www'
              `dotcloud -A #{app} #{service} #{cmd}`
            end

            def service_name
              "dotCloud"
            end
        end
      end
    end
  end
end
