require 'digest/sha2'
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
        enable :static
        set :root, File.expand_path('../../../../../', __FILE__)
        set :start, Time.now.utc

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

          use Rack::Deflater
        end

        helpers do
          def auth_disabled?
            (
              ENV['API_TOKEN'].nil? || ENV['API_TOKEN'].strip.empty?
            ) && (
              settings.development? || settings.testing?
            )
          end
        end

        before '/script' do
          return if auth_disabled?

          unless env.key?('HTTP_AUTHORIZATION')
            halt 401, 'missing Authorization header'
          end

          type, token = env['HTTP_AUTHORIZATION'].to_s.split(' ', 2)

          ENV['API_TOKEN'].split(',').each do |valid_token|
            return if secure_eq(type, 'token') && secure_eq(token, valid_token)
          end

          halt 403, 'access denied'
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
              repository: payload.fetch('repository', {}).fetch('slug', '???'),
              job: payload.fetch('job', {}).fetch('id', '???'),
            )
          end

          compiled = Travis::Build.script(payload).compile

          content_type 'application/x-sh'
          status 200
          compiled
        end

        get('/') { uptime }
        get('/uptime') { uptime }
        get('/boom') { raise StandardError, ':bomb:' }

        private

        def uptime
          headers(
            'Travis-Build-Uptime' => "#{Time.now.utc - settings.start}s",
            'Travis-Build-Version' => Travis::Build.version
          )
          status 204
        end

        def secure_eq(a, b)
          Rack::Utils.secure_compare(
            Digest::SHA256.hexdigest(a.to_s),
            Digest::SHA256.hexdigest(b.to_s)
          )
        end
      end
    end
  end
end
