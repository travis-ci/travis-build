require 'json'
require 'rack/ssl'
require 'sinatra/base'
require 'metriks'

require 'travis/build'
require 'travis/api/build/sentry'
require 'travis/api/build/metriks'

module Travis
  module Api
    module Build
      class App < Sinatra::Base
        before '/script' do
          return if ENV['API_TOKEN'].nil? || ENV['API_TOKEN'].empty?

          type, token = env['HTTP_AUTHORIZATION'].to_s.split(' ', 2)

          unless type == 'token' && token == ENV['API_TOKEN']
            halt 403, 'access denied'
          end
        end

        configure(:production, :staging) do
          use Rack::SSL
        end

        configure do
          if ENV['SENTRY_DSN']
            use Sentry
          end

          if ENV.key?('LIBRATO_EMAIL') && ENV.key?('LIBRATO_TOKEN') && ENV.key?('LIBRATO_SOURCE')
            use Metriks
          end
        end

        error JSON::ParserError do
          status 400
          env['sinatra.error'].message
        end

        error do
          status 500
          env['sinatra.error'].message
        end

        post '/script' do
          payload = JSON.parse(request.body.read)

          if ENV['SENTRY_DSN']
            Raven.extra_context(
              repository: payload['repository']['slug'],
              job: payload['job']['id'],
            )
          end

          content_type :txt
          Travis::Build.script(payload).compile
        end

        get '/uptime' do
          status 204
        end
      end
    end
  end
end
