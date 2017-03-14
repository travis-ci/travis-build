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
          if access_key
            sh.export 'SAUCE_ACCESS_KEY', access_key, echo: false
          else
            decode_jwt
          end

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

          def decode_jwt
            tokens = {}
            Array(config[:jwt]).each do |secret|
              pull_request = self.data.pull_request ? self.data.pull_request : ""
              now = Time.now.to_i()
              payload = {
                "iss" => "Travis CI, GmbH",
                "slug" => self.data.slug,
                "pull-request" => pull_request,
                "exp" => now+5400,
                "iat" => now
              }
              begin
                key, secret = secret.split('=').map(&:strip)
                tokens[key] = JWT.encode(payload, secret)
              rescue Exception
                sh.echo "There was an error while encoding JWT. If the secret is encrypted, ensure that it is encrypted correctly.", ansi: :yellow
              end
            end
            return if tokens.empty?
            sh.fold 'addons_jwt' do
              sh.echo 'Initializing JWT', ansi: :yellow
              tokens.each do |key, val|
                sh.export key, val, echo: false
              end
            end
          end
      end
    end
  end
end
