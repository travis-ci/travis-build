require 'faraday'

module Travis
  module Build
    module Connection
      class Http < Faraday::Connection
        def initialize(config)
          super(nil, :ssl => ssl_options(config))
        end

        def ssl_options(config)
          if config.ssl_ca_path?
            { :ca_path => config.ssl_ca_path }
          else
            { :ca_file => File.expand_path('certs/cacert.pem') }
          end
        end
      end
    end
  end
end

