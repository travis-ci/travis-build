module Travis
  class Build
    module Job

      # Job that performs the unit of work of configuring a build request.
      #
      # I.e. this simply does an HTTP GET request to the Github API and
      # passes the result back to travis-hub (which then will either reject
      # the request based on the configuration or create and run a Build).
      class Configure
        include Logging

        log_header { "#{Thread.current[:log_header]}:job:configure" }

        attr_reader :http, :commit

        def initialize(http, commit)
          @http = http
          @commit = commit
        end

        def run
          { 'config' => fetch.merge('.configured' => true) }
        end

        protected

          def fetch
            if response.success?
              parse(response.body)
            else
              # TODO log error
              {}
            end
          end

          def response
            @response ||= http.get(commit.config_url)
          end

          def parse(yaml)
            YAML.load(yaml) || {}
          rescue => e
            log_exception(e)
            {} # TODO include '.invalid' => true here?
          end
      end
    end
  end
end
