require 'raven'
require 'raven/integrations/rack'
require 'sinatra/base'

module Travis
  module Api
    module Build
      class Sentry < Sinatra::Base
        configure do
          Raven.configure do |config|
            config.tags = { environment: environment }
          end
          use Raven::Rack
        end
      end
    end
  end
end
