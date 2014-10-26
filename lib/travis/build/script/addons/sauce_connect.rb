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
            if config[:username]
              sh.export 'SAUCE_USERNAME', config[:username], echo: false
            end
            if config[:access_key]
              sh.export 'SAUCE_ACCESS_KEY', config[:access_key], echo: false
            end

            sh.fold 'sauce_connect' do
              sh.echo 'Starting Sauce Connect', ansi: :yellow
              sh.cmd "curl -L https://gist.githubusercontent.com/henrikhodne/9322897/raw/sauce-connect.sh | bash", assert: false
              sh.export 'TRAVIS_SAUCE_CONNECT', 'true', echo: false
            end
          end
        end
      end
    end
  end
end
