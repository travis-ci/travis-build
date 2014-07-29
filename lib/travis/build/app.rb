require 'json'
require 'rack/ssl'
require 'sinatra/base'
require 'metriks'

require 'travis/build'

module Travis
  module Build
    class App < Sinatra::Base
      before do
        return if ENV["API_TOKEN"].nil? || ENV["API_TOKEN"].empty?

        type, token = env["HTTP_AUTHORIZATION"].to_s.split(" ", 2)

        unless type == "token" && token == ENV["API_TOKEN"]
          halt 403, "access denied"
        end

        env['metriks.request.start'] ||= Time.now.utc
      end

      after do
        if queue_start = time(env['HTTP_X_QUEUE_START']) || time(env['HTTP_X_REQUEST_START'])
          time = env['metriks.request.start'] - queue_start
          ::Metriks.timer('build_api.request_queue').update(time)
        end

        time = Time.now.utc - env['metriks.request.start']

        ::Metriks.timer("build_api.requests").update(time)
        ::Metriks.timer("build_api.request.#{request.request_method.downcase}").update(time)
        ::Metriks.timer("build_api.request.status.#{response.status.to_s[0]}").update(time)
      end

      def time(value)
        value = value.to_f
        start = env['metriks.request.start'].to_f
        value /= 1000 while value > start
        Time.at(value) if value > 946684800
      end

      configure(:production, :staging) do
        use(Rack::Config) { |env| env['metriks.request.start'] ||= Time.now.utc }
        use Rack::SSL
      end

      configure do
        if ENV["SENTRY_DSN"]
          require "raven"
          use Raven::Rack
        end

        if ENV.key?("LIBRATO_EMAIL") && ENV.key?("LIBRATO_TOKEN") && ENV.key?("LIBRATO_SOURCE")
          require "metriks/librato_metrics_reporter"

          Metriks::LibratoMetricsReporter.new(
            ENV["LIBRATO_EMAIL"],
            ENV["LIBRATO_TOKEN"],
            source: ENV["LIBRATO_SOURCE"],
            on_error: proc { |ex| puts "librato error: #{ex.message} (#{ex.response.body})" }
          ).start
        end
      end

      error JSON::ParserError do
        status 400
        env["sinatra.error"].message
      end

      error do
        status 500
        env["sinatra.error"].message
      end

      post "/script" do
        payload = JSON.parse(request.body.read)

        content_type :txt
        Travis::Build.script(payload).compile
      end
    end
  end
end

