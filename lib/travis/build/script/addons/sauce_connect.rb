module Travis
  module Build
    class Script
      module Addons
        class SauceConnect
          SUPER_USER_SAFE = true

          def initialize(script, config)
            @script = script
            @config = config.respond_to?(:to_hash) ? config.to_hash : {}
          end

          def before_script
            if @config[:username]
              @script.set 'SAUCE_USERNAME', @config[:username], echo: false
            end
            if @config[:access_key]
              @script.set 'SAUCE_ACCESS_KEY', @config[:access_key], echo: false
            end

            @script.fold 'sauce_connect' do |sh|
              sh.echo 'Starting Sauce Connect', ansi: :yellow
              sh.cmd "curl -L https://gist.githubusercontent.com/henrikhodne/9322897/raw/sauce-connect.sh | bash", assert: false
              sh.set 'TRAVIS_SAUCE_CONNECT', 'true', echo: false
            end
          end
        end
      end
    end
  end
end
