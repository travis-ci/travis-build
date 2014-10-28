require "raven"
require "sinatra/base"

module Travis
  module Build
    module App
      class Sentry < Sinatra::Base
        configure do
          Raven.configure do |config|
            config.tags = {
              environment: environment,
            }
          end

          use Raven::Rack
        end
      end
    end
  end
end
