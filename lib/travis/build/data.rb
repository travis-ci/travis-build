require 'faraday'
require 'core_ext/hash/deep_merge'
require 'core_ext/hash/deep_symbolize_keys'
require 'travis/github_apps'
require 'travis/build/data/ssh_key'

# actually, the worker payload can be cleaned up a lot ...

module Travis
  module Build
    class Data
      DEFAULTS = { }

      DEFAULT_CACHES = {
        bundler:   false,
        cocoapods: false,
        composer:  false,
        ccache:    false,
        pip:       false
      }

      attr_reader :data, :language_default_p

      def initialize(data, defaults = {})
        data = data.deep_symbolize_keys
        defaults = defaults.deep_symbolize_keys
        @language_default_p = data[:language_default_p]
        @data = DEFAULTS.deep_merge(defaults.deep_merge(data))
      end

      def [](key)
        data[key]
      end

      def key?(key)
        data.key?(key)
      end

      def language
        config[:language]
      end

      def group
        config[:group]
      end

      def dist
        config[:dist]
      end

      def urls
        data[:urls] || {}
      end

      def config
        data[:config]
      end

      def hosts
        data[:hosts] || {}
      end

      def cache_options
        data[:cache_settings] || data[:cache_options] || {}
      end

      def cache(input = config[:cache])
        case input
        when Hash           then input
        when Array          then input.map { |e| cache(e) }.inject(:merge)
        when String, Symbol then { input.to_sym => true }
        when nil            then {} # for ruby 1.9
        when false          then Hash[DEFAULT_CACHES.each_key.with_object(false).to_a]
        else input.to_h
        end
      end

      def cache?(type, default = DEFAULT_CACHES[type])
        type &&= type.to_sym
        !!cache.fetch(type) { default }
      end

      def env_vars
        data[:env_vars] || []
      end

      def ssh_key?
        !!ssh_key
      end

      def ssh_key
        @ssh_key ||= if ssh_key = data[:ssh_key]
          SshKey.new(ssh_key[:value], ssh_key[:source], ssh_key[:encoded])
        elsif source_key = data[:config][:source_key]
          SshKey.new(source_key, nil, true)
        end
      end

      def pull_request?
        !!pull_request
      end

      def pull_request
        job[:pull_request]
      end

      def secure_env?
        !!job[:secure_env_enabled]
      end

      def secure_env_removed?
        !!job[:secure_env_removed]
      end

      def disable_sudo?
        !!data[:paranoid]
      end

      def source_host
        source_url =~ %r(^(?:https?|git)(?:://|@)([^/]*?)(?:/|:)) && $1
      end

      def api_url
        repository[:api_url]
      end

      def source_url
        repository[:source_url]
      end

      def slug
        repository[:slug] || raise('data.slug must not be empty')
      end

      def github_id
        repository.fetch(:github_id)
      end

      def default_branch
        repository[:default_branch]
      end

      def commit
        job[:commit] || ''
      end

      def branch
        job[:branch] || ''
      end

      def tag
        job[:tag]
      end

      def ref
        job[:ref]
      end

      def job
        data[:job] || {}
      end

      def build
        data[:source] || data[:build] || {} # TODO standarize the payload on :build
      end

      def repository
        data[:repository] || {}
      end

      def token
        installation? ? installation_token : data[:oauth_token]
      end

      def debug_options
        job[:debug_options] || {}
      end

      def prefer_https?
        source_url.downcase.start_with? "https"
      end

      def installation?
        !!installation_id
      end

      def installation_id
        repository[:installation_id]
      end

      def installation_token
        GithubApps.new(installation_id).access_token
      end
    end
  end
end
