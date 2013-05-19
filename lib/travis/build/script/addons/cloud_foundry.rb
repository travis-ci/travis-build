require 'travis/build/script/addons/deploy'

module Travis
  module Build
    class Script
      module Addons
        class CloudFoundry < Deploy
          private
            def cli_tool
              config.fetch(:cli_tool) { config[:version].to_i == 1 ? 'cf' : 'vmc' }
            end

            def deploy
              cf "target #{option(:target)}"
              silent { cf "login --email #{option(:email)} --password #{option(:password)}" }
              cf "push #{app}"
            end

            def tools
              `gem install #{cli_tool}`
            end

            def cf(cmd)
              `#{cli_tool} #{cmd}`
            end
        end
      end
    end
  end
end
