require 'core_ext/hash/deep_merge'
require 'core_ext/hash/deep_symbolize_keys'

# actually, the worker payload can be cleaned up a lot ...

module Travis
  module Build
    class Data
      autoload :Env, 'travis/build/data/env'
      autoload :Var, 'travis/build/data/var'

      DEFAULTS = { }

      DEFAULT_CACHES = {
        apt:     false,
        bundler: false
      }

      attr_reader :data

      def initialize(data, defaults = {})
        data = data.deep_symbolize_keys
        defaults = defaults.deep_symbolize_keys
        @data = DEFAULTS.deep_merge(defaults.deep_merge(data))
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

      def paranoid_mode?
        data.fetch(:paranoid, false)
      end

      def skip_resolv_updates?
        data.fetch(:skip_resolv_updates, false)
      end

      def skip_etc_hosts_fix?
        data.fetch(:skip_etc_hosts_fix, false)
      end

      def cache_options
        data[:cache_options] || {}
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
        @env_vars ||= Env.new(self).vars
      end

      def env_vars_groups
        @env_vars_groups ||= Env.new(self).vars_groups
      end

      def raw_env_vars
        data[:env_vars] || []
      end

      class SshKey < Struct.new(:value, :source, :encoded)
        def encoded?
          encoded
        end
      end

      def ssh_key
        if ssh_key = data[:ssh_key]
          SshKey.new(ssh_key[:value], ssh_key[:source], ssh_key[:encoded])
        elsif source_key = data[:config][:source_key]
          SshKey.new(source_key, nil, true)
        end
      end

      def pull_request
        job[:pull_request]
      end

      def secure_env_enabled?
        job[:secure_env_enabled]
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
        repository[:slug]
      end

      def commit
        job[:commit]
      end

      def branch
        job[:branch]
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
        data[:oauth_token]
      end
    end
  end
end
