require 'metriks'
require 'metriks/librato_metrics_reporter'
require 'sinatra/base'

module Travis
  module Api
    module Build
      class Metriks < Sinatra::Base
        configure do
          ::Metriks::LibratoMetricsReporter.new(
            Travis::Build.config.librato.email.to_s,
            Travis::Build.config.librato.token.to_s,
            source: Travis::Build.config.librato.source.to_s,
            on_error: proc { |ex| puts "librato error: #{ex.message} (#{ex.response.body})" }
          ).start

          use(Rack::Config) { |env| env['metriks.request.start'] ||= Time.now.utc }
        end

        before do
          env['metriks.request.start'] ||= Time.now.utc
        end

        after do
          if queue_start = time(env['HTTP_X_QUEUE_START']) || time(env['HTTP_X_REQUEST_START'])
            time = env['metriks.request.start'] - queue_start
            ::Metriks.timer('build_api.request_queue').update(time)
          end

          time = Time.now.utc - env['metriks.request.start']

          ::Metriks.timer('build_api.requests').update(time)
          ::Metriks.timer("build_api.request.#{request.request_method.downcase}").update(time)
          ::Metriks.timer("build_api.request.status.#{response.status.to_s[0]}").update(time)
        end

        def time(value)
          value = value.to_f
          start = env['metriks.request.start'].to_f
          value /= 1000 while value > start
          Time.at(value) if value > 946684800
        end
      end
    end
  end
end
