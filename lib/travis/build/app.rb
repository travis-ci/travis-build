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
        payload = JSON.parse(request.body.read)

        config = { hosts: {} }
        config[:hosts][:npm_cache] = ENV["NPM_CACHE_HOST"] if ENV.key?("NPM_CACHE_HOST")
        config[:hosts][:apt_cache] = ENV["APT_CACHE_HOST"] if ENV.key?("APT_CACHE_HOST")
        config[:paranoid] = true if ENV["PARANOID_MODE"] == "true"
        config[:skip_resolv_updates] = true if ENV["SKIP_RESOLV_UPDATES"] == "true"
        config[:skip_etc_hosts_fix] = true if ENV["SKIP_ETC_HOSTS_FIX"] == "true"

        content_type :txt
        Travis::Build.script(payload.merge(config)).compile
      end

      def config
        config = { hosts: {}, cache_options: {} }
        config[:hosts][:npm_cache] = ENV["NPM_CACHE_HOST"] if ENV.key?("NPM_CACHE_HOST")
        config[:hosts][:apt_cache] = ENV["APT_CACHE_HOST"] if ENV.key?("APT_CACHE_HOST")
        config[:paranoid] = true if ENV["PARANOID_MODE"] == "true"
        config[:skip_resolv_updates] = true if ENV["SKIP_RESOLV_UPDATES"] == "true"
        config[:skip_etc_hosts_fix] = true if ENV["SKIP_ETC_HOSTS_FIX"] == "true"

        config[:cache_options][:fetch_timeout] = ENV["CACHE_FETCH_TIMEOUT"] if ENV.key?("CACHE_FETCH_TIMEOUT")
        config[:cache_options][:push_timeout] = ENV["CACHE_FETCH_TIMEOUT"] if ENV.key?("CACHE_FETCH_TIMEOUT")
        if ENV["CACHE_TYPE"] == "s3"
          config[:cache_options][:type] = "s3"
          config[:cache_options][:s3] = {}
          config[:cache_options][:s3][:access_key_id] = ENV.fetch("CACHE_S3_ACCESS_KEY_ID")
          config[:cache_options][:s3][:secret_access_key] = ENV.fetch("CACHE_S3_SECRET_ACCESS_KEY")
          config[:cache_options][:s3][:bucket] = ENV.fetch("CACHE_S3_BUCKET")
          config[:cache_options][:s3][:scheme] = ENV["CACHE_S3_SCHEME"] if ENV.key?("CACHE_S3_SCHEME")
          config[:cache_options][:s3][:region] = ENV["CACHE_S3_REGION"] if ENV.key?("CACHE_S3_REGION")
        end

        config
      end
    end
  end
end

