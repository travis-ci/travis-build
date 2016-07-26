require 'travis/build/addons/base'
require 'jwt'

module Travis
  module Build
    class Addons
      class Jwt < Base
        SUPER_USER_SAFE = true

        def before_before_script
          tokens = {}
          Array(config).each do |secret|
            key, secret = secret.split('=').map(&:strip)
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
              tokens[key] = JWT.encode(payload, secret)
            rescue Exception => e
              sh.failure "JWT Encode Error: #{e.message}"
              []
            end
          end
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
