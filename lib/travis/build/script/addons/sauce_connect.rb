module Travis
  module Build
    class Script
      module Addons
        class SauceConnect
          def initialize(script, config)
            @script = script
            @config = config.respond_to?(:to_hash) ? config.to_hash : {}
          end

          def run
            if @config[:username]
              @script.set 'SAUCE_USERNAME', @config[:username], echo: false, assert: false
            end
            if @config[:access_key]
              @script.set 'SAUCE_ACCESS_KEY', @config[:access_key], echo: false, assert: false
            end

            @script.cmd 'curl https://gist.github.com/santiycr/5139565/raw/sauce_connect_setup.sh | bash', assert: false
            @script.set 'TRAVIS_SAUCE_CONNECT', 'true', echo: false, assert: false
          end
        end
      end
    end
  end
end

