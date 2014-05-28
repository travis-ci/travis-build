require 'json'
require 'sinatra/base'
require 'travis/build'

module Travis
  module Build
    class App < Sinatra::Base
      before do
        return if ENV["API_TOKEN"].nil? || ENV["API_TOKEN"].empty?

        type, token = env["HTTP_AUTHORIZATION"].to_s.split(" ", 2)

        unless type == "token" && token == ENV["API_TOKEN"]
          halt 403, "access denied"
        end
      end

      if ENV["SENTRY_DSN"]
        require "raven"
        use Raven::Rack
      end

      post "/script" do
        data = JSON.parse(request.body.read)

        content_type :txt
        Travis::Build.script(data).compile
      end
    end
  end
end

