require 'faraday'

module Travis
  class Build
    module Connection
      # Models an http connection on top of faraday but encapsulating details
      # about the ssl cert
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

