require 'jwt'

module Travis
  module Build
    class Addons
      module JsonWebToken

        def decode_jwt_to(env_name, exp: 5400)
          return unless config[:jwt]

          pull_request = self.data.pull_request ? self.data.pull_request : ""
          now = Time.now.to_i()
          payload = {
            "iss" => "Travis CI, GmbH",
            "slug" => self.data.slug,
            "pull-request" => pull_request,
            "exp" => now+exp,
            "iat" => now
          }

          val = config[:jwt].match(/^(?:#{env_name}=)?(.*)$/)[1]

          sh.fold 'addons_jwt' do
            sh.echo 'Initializing JWT', ansi: :yellow

            sh.export env_name, JWT.encode(payload, val), echo: false
          end
        end

      end
    end
  end
end
