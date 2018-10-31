require 'travis/build/addons/base'

module Travis
  module Build
    class Addons
      class SauceConnect < Base
        SUPER_USER_SAFE = true

        def after_header
          sh.export 'TRAVIS_SAUCE_CONNECT_PID', 'unset', echo: false
          sh.export 'TRAVIS_SAUCE_CONNECT_LINUX_DOWNLOAD_URL', linux_download_url, echo: false
          sh.export 'TRAVIS_SAUCE_CONNECT_OSX_DOWNLOAD_URL', osx_download_url, echo: false
          sh.export 'TRAVIS_SAUCE_CONNECT_VERSION', sc_version, echo: false
          sh.export 'TRAVIS_SAUCE_CONNECT_APP_HOST', '${TRAVIS_APP_HOST}', echo: false
          sh.raw bash('travis_start_sauce_connect')
          sh.raw bash('travis_stop_sauce_connect')
        end

        def before_before_script
          sh.export 'SAUCE_USERNAME', username, echo: false if username
          sh.export 'SAUCE_ACCESS_KEY', access_key, echo: false if access_key

          if direct_domains
            sh.export 'SAUCE_DIRECT_DOMAINS', "'-D #{direct_domains}'", echo: false
          end

          if no_ssl_bump_domains
            sh.export 'SAUCE_NO_SSL_BUMP_DOMAINS', "'-B #{no_ssl_bump_domains}'", echo: false
          end

          if tunnel_domains
            sh.export 'SAUCE_TUNNEL_DOMAINS', "'-t #{tunnel_domains}'", echo: false
          end

          sh.fold 'sauce_connect.start' do
            sh.echo 'Starting Sauce Connect', echo: false, ansi: :yellow
            sh.cmd 'travis_start_sauce_connect', assert: true, echo: true, timing: true, retry: true
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

          def direct_domains
            config[:direct_domains]
          end

          def no_ssl_bump_domains
            config[:no_ssl_bump_domains]
          end

          def tunnel_domains
            config[:tunnel_domains]
          end

          def linux_download_url
            @linux_download_url ||= sc_config['linux']['download_url'].to_s.output_safe
          end

          def osx_download_url
            @osx_download_url ||= sc_config['osx']['download_url'].to_s.output_safe
          end

          def sc_version
            @sc_version ||= sc_config['version'].to_s.output_safe
          end

          def sc_config
            Travis::Build.config.sc_data.fetch(
              'Sauce Connect',
              {
                'linux' => { 'download_url' => '' },
                'osx' => { 'download_url' => '' },
                'version' => ''
              }
            )
          end
      end
    end
  end
end
