require 'travis/build/addons/base'
require 'jwt'

module Travis
  module Build
    class Addons
      class Jwt < Base
        SUPER_USER_SAFE = true

        def before_before_script
          secrets = nil
          if config.is_a?(String)
            secrets = [config]
          else
            secrets = config.values
          end

          tokens = {}
          secrets.each do |secret|
            key, secret = secret.split('=').map(&:strip)
            pull_request = self.data.pull_request ? self.data.pull_request : ""
            payload = {"slug" => self.data.slug,
                      "pull-request" => pull_request,
                      "iat" => Time.now.to_i()}
            token = JWT.encode(payload, secret)
            tokens[key] = token
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
