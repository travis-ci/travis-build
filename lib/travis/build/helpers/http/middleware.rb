require 'travis/api/build/metriks'

module Travis
  module Build
    module Http
      class Middleware < Faraday::Middleware
        MSG = "GitHub request failed url=%s rate_limit=%s github_request_id=%s status=%s"

        def call(request_env)
          Travis::Build.logger.info "Using #{self}"
          @app.call(request_env).on_complete do |response_env|
            rate_limit = rate_limit_info(response_env[:response_headers])
            meter(rate_limit[:remaining])

            log_request_info(request_env, response_env, rate_limit) unless response_env.success?
          end
        end

        def log_request_info(request_env, response_env, rate_limit)
          Travis::Build.logger.warn MSG % [request_env[:url], rate_limit, github_request_id(response_env[:response_headers]), response_env.status ]
        end

        def meter(remaining)
          ::Metriks.meter('travis.github_api.requests').mark
          ::Metriks.gauge('travis.github_api.rate_limit_remaining') { remaining } if remaining
        end

        def rate_limit_present?(headers)
          headers.present? &&
          headers['x-ratelimit-limit'].present? &&
          headers['x-ratelimit-remaining'].present? &&
          headers['x-ratelimit-reset'].present?
        end

        def rate_limit_info(headers)
          return {} unless rate_limit_present?(headers)

          {
            limit: headers['x-ratelimit-limit'].to_i,
            remaining: headers['x-ratelimit-remaining'].to_i,
            next_limit_reset_in: headers['x-ratelimit-reset'].to_i - Time.now.to_i
          }
        end

        def github_request_id(headers)
          headers['x-github-request-id']
        end
      end
    end
  end
end
