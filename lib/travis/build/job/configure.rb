module Travis
  module Build
    module Job
      class Configure
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
            response.success? ? parse(response.body) : {}
          end

          def response
            @response ||= http.get(commit.config_url)
          end

          def parse(yaml)
            YAML.load(yaml) || {} rescue {}
          end
      end
    end
  end
end
