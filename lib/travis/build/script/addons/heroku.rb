require 'travis/build/script/addons/deploy'

module Travis
  module Build
    class Script
      module Addons
        class Heroku < Deploy
          private
            def export
              { 'HEROKU_API_KEY' => option(:api_key) }
            end

            def tools
              `wget -qO- https://toolbelt.heroku.com/install-ubuntu.sh | sh`
              `heroku plugins:install https://github.com/ddollar/heroku-anvil`
            end

            def deploy
              `heroku build -r #{app}`
            end

            def run(cmd)
              `heroku run #{cmd} --app #{app}`
            end
        end
      end
    end
  end
end
