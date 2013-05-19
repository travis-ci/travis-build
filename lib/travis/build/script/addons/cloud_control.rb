require 'travis/build/script/addons/deploy'

module Travis
  module Build
    class Script
      module Addons
        class CloudControl < Deploy
          private
            def tools
              `pip install cctrl`
            end

            def deploy
              silent do
                `mkdir ~/.cloudControl`
                `echo '{"token": "#{option(:api_key)}"}' > ~/.cloudControl/token.json`
              end
              #fail "magic deploy key code goes here" # TODO: FIXME
              `cctrlapp #{app} push`
            end

            def fold_name
              "cctrl"
            end

            def service_name
              "cloudControl"
            end
        end
      end
    end
  end
end
