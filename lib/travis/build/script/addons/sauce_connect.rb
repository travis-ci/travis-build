module Travis
  module Build
    class Script
      module Addons
        class SauceConnect
          SUPER_USER_SAFE = true

          attr_reader :sh, :config

          def initialize(script, config)
            @sh = script.sh
            @config = config.respond_to?(:to_hash) ? config.to_hash : {}
          end

          def before_script
            sh.export 'SAUCE_USERNAME', config[:username], echo: false if config[:username]
            sh.export 'SAUCE_ACCESS_KEY', config[:access_key], echo: false if config[:access_key]

            sh.fold 'sauce_connect' do
              sh.echo 'Starting Sauce Connect', ansi: :green
              sh.cmd "curl -L https://gist.githubusercontent.com/henrikhodne/9322897/raw/sauce-connect.sh | bash"
              sh.export 'TRAVIS_SAUCE_CONNECT', 'true', echo: false
            end
          end
        end
      end
    end
  end
end

