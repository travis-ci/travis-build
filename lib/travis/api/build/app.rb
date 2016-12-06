# frozen_string_literal: true
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
        set :auth_salt, "#{ENV.fetch('SALT', 'zzz')}".untaint

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
            halt(
              401,
              { 'WWW-Authenticate' => 'token' },
              'missing Authorization header'
            )
          end

          type, token = env['HTTP_AUTHORIZATION'].to_s.split(' ', 2)
          api_tokens.each do |hashed_valid_token|
            return if secure_hashed_eq(hashed_type_token, type) &&
                      secure_hashed_eq(hashed_valid_token, token)
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

        def secure_hashed_eq(hashed, b, salt: settings.auth_salt)
          Rack::Utils.secure_compare(
            hashed,
            Digest::SHA256.hexdigest(salt + b.to_s)
          )
        end

        def api_tokens(salt: settings.auth_salt)
          @api_tokens ||= ENV['API_TOKEN'].to_s.split(',')
                                          .map(&:strip)
                                          .reject(&:empty?)
                                          .map do |s|
            Digest::SHA256.hexdigest(salt + s)
          end
        end

        def hashed_type_token(salt: settings.auth_salt)
          @hashed_type_token ||= Digest::SHA256.hexdigest(salt + 'token')
        end
      end
    end
  end
end
