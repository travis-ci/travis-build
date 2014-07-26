module Travis
  module Build
    class Script
      module Addons
        class SauceConnect
          SUPER_USER_SAFE = true

          attr_reader :sh, :config

          def initialize(sh, config)
            @sh = sh
            @config = config.respond_to?(:to_hash) ? config.to_hash : {}
          end

          def before_script
            if @config[:username]
              set 'SAUCE_USERNAME', config[:username]
            end
            if @config[:access_key]
              set 'SAUCE_ACCESS_KEY', config[:access_key]
            end

            sh.fold 'sauce_connect' do
              echo 'Starting Sauce Connect', ansi: :green
              cmd "curl -L https://gist.githubusercontent.com/henrikhodne/9322897/raw/sauce-connect.sh | bash"
              set 'TRAVIS_SAUCE_CONNECT', 'true', echo: false
            end
          end
        end
      end
    end
  end
end

