require 'travis/build/addons/base'

module Travis
  module Build
    class Addons
      class SauceConnect < Base
        SUPER_USER_SAFE = true
        SOURCE_URL = 'https://gist.githubusercontent.com/henrikhodne/9322897/raw/sauce-connect.sh'

        def before_before_script
          sh.export 'SAUCE_USERNAME', username, echo: false if username
          sh.export 'SAUCE_ACCESS_KEY', access_key, echo: false if access_key

          sh.fold 'sauce_connect' do
            sh.echo 'Starting Sauce Connect', ansi: :yellow
            sh.cmd "curl -L #{SOURCE_URL} | bash", assert: false, echo: true, timing: true
            sh.export 'TRAVIS_SAUCE_CONNECT', 'true', echo: false
          end
        end

        private

          def username
            config[:username]
          end

          def access_key
            config[:access_key]
          end
      end
    end
  end
end
