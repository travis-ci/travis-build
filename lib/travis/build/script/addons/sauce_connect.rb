module Travis
  module Build
    class Script
      module Addons
        class SauceConnect
          REQUIRES_SUPER_USER = false

          def initialize(script, config)
            @script = script
            @config = config.respond_to?(:to_hash) ? config.to_hash : {}
          end

          def before_script
            if @config[:username]
              @script.set 'SAUCE_USERNAME', @config[:username], echo: false, assert: false
            end
            if @config[:access_key]
              @script.set 'SAUCE_ACCESS_KEY', @config[:access_key], echo: false, assert: false
            end

            @script.fold('sauce_connect') do |script|
              script.cmd 'echo -e "\033[33;1mStarting Sauce Connect\033[0m"', assert: false, echo: false
              script.cmd "curl -L https://gist.githubusercontent.com/santiycr/5139565/raw/sauce_connect_setup.sh | bash", assert: false
              script.set 'TRAVIS_SAUCE_CONNECT', 'true', echo: false, assert: false
            end
          end
        end
      end
    end
  end
end

