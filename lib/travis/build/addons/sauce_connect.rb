require 'travis/build/addons/base'

module Travis
  module Build
    class Addons
      class SauceConnect < Base
        SUPER_USER_SAFE = true
        TEMPLATES_PATH = File.expand_path('templates', __FILE__.sub('.rb', ''))

        def after_header
          sh.raw template('sauce_connect.sh')
        end

        def before_before_script
          sh.export 'SAUCE_USERNAME', username, echo: false if username
          sh.export 'SAUCE_ACCESS_KEY', access_key, echo: false if access_key

          sh.fold 'sauce_connect.start' do
            sh.echo 'Starting Sauce Connect', echo: false, ansi: :yellow
            sh.cmd 'travis_start_sauce_connect', assert: false, echo: true, timing: true
            sh.export 'TRAVIS_SAUCE_CONNECT', 'true', echo: false
          end
        end

        def after_after_script
          sh.fold 'sauce_connect.stop' do
            sh.echo 'Stopping Sauce Connect', echo: false, ansi: :yellow
            sh.cmd 'travis_stop_sauce_connect', assert: false, echo: true, timing: true
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
