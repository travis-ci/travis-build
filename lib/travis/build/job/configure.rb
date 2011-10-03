module Travis
  module Build
    module Job
      class Configure
        attr_reader :shell, :config

        def initialize(shell, config)
          @shell = shell
          @config = config
        end

        def run
          fetch.merge('.configured' => true)
        end

        protected

          def fetch
            response = Faraday.new(nil, connection_options).get(url)
            response.success? ? parse(response.body) : {}
          end

          def url
            "#{repository.raw_url}/#{build.commit}/.travis.yml"
          end

          def parse(yaml)
            YAML.load(yaml) || {}
          rescue Exception => e
            # TODO should report this exception back as part of the log
            {}
          end

          def connection_options
            options = {}
            if Travis::Worker.config.ssl_ca_path
              options[:ssl] = { :ca_path => Travis::Worker.config.ssl_ca_path }
            else
              options[:ssl] = { :ca_file => File.expand_path('certs/cacert.pem') }
            end
            options
          end
      end
    end
  end
end

