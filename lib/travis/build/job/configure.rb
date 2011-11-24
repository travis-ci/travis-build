module Travis
  class Build
    module Job
      class Configure
        include Logging

        attr_reader :http, :commit
        log_header { "#{Thread.current[:log_header]}:job:configure" }

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
