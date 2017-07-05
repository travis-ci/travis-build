require 'hashr'
require 'travis/config'

module Travis
  module Build
    class Config < Travis::Config
      extend Hashr::Env
      self.env_namespace = 'travis_build'

      def go_version_aliases_hash
        @go_version_aliases_hash ||= aliases_hash(:go_version_aliases)
      end

      def ghc_version_aliases_hash
        @ghc_version_aliases_hash ||= aliases_hash(:ghc_version_aliases)
      end

      private def aliases_hash(key)
        {}.tap do |aliases|
          self[key].untaint.split(',').each do |v|
            key, value = v.strip.split(':', 2)
            next if key.nil? || value.nil?
            aliases[key] = value
          end
        end
      end

      def self.latest_semver_aliases(major_full)
        {}.tap do |aliases|
          major_full.each do |major, full|
            fullparts = full.split('.')
            aliases.merge!(
              major => full,
              "#{major}.x" => full,
              "#{major}.x.x" => full,
              "#{fullparts[0]}.#{fullparts[1]}.x" => full
            )
          end
        end
      end

      define(
        api_token: ENV.fetch(
          'TRAVIS_BUILD_API_TOKEN', ENV.fetch('API_TOKEN', '')
        ),
        app_host: ENV.fetch('TRAVIS_BUILD_APP_HOST', ''),
        apt_package_whitelist: {
          precise: ENV.fetch('TRAVIS_BUILD_APT_PACKAGE_WHITELIST_PRECISE', ''),
          trusty: ENV.fetch('TRAVIS_BUILD_APT_PACKAGE_WHITELIST_TRUSTY', '')
        },
        apt_source_whitelist: {
          precise: ENV.fetch('TRAVIS_BUILD_APT_SOURCE_WHITELIST_PRECISE', ''),
          trusty: ENV.fetch('TRAVIS_BUILD_APT_SOURCE_WHITELIST_TRUSTY', '')
        },
        apt_whitelist_skip: ENV.fetch('TRAVIS_BUILD_APT_WHITELIST_SKIP', ''),
        cabal_default: ENV.fetch('TRAVIS_BUILD_CABAL_DEFAULT', '1.22'),
        auth_disabled: ENV.fetch('TRAVIS_BUILD_AUTH_DISABLED', ''),
        enable_debug_tools: ENV.fetch(
          'TRAVIS_BUILD_ENABLE_DEBUG_TOOLS',
          ENV.fetch('TRAVIS_ENABLE_DEBUG_TOOLS', '')
        ),
        etc_hosts_pinning: ENV.fetch(
          'TRAVIS_BUILD_ETC_HOSTS_PINNING', ENV.fetch('ETC_HOSTS_PINNING', '')
        ),
        ghc_default: ENV.fetch('TRAVIS_BUILD_GHC_DEFAULT', '7.10.3'),
        ghc_version_aliases: ENV.fetch(
          'TRAVIS_BUILD_GHC_VERSION_ALIASES', (
            {
              '6.12.x' => '6.12.3',
              '7.0.x' => '7.0.4',
              '7.10.x' => '7.10.3',
              '7.2.x' => '7.2.2',
              '7.4.x' => '7.4.2',
              '7.6.x' => '7.6.3',
              '7.8.x' => '7.8.4',
              '8.0.x' => '8.0.2'
            }.map { |k, v| "#{k}:#{v}" }.join(',')
          )
        ),
        gimme: {
          force_reinstall: ENV.fetch('TRAVIS_BUILD_GIMME_FORCE_REINSTALL', ''),
          url: ENV.fetch(
            'TRAVIS_BUILD_GIMME_URL',
            'https://raw.githubusercontent.com/travis-ci/gimme/v1.1.0/gimme'
          )
        },
        go_version: ENV.fetch('TRAVIS_BUILD_GO_VERSION', '1.8.3'),
        go_version_aliases: ENV.fetch(
          'TRAVIS_BUILD_GO_VERSION_ALIASES', (
            latest_semver_aliases(
              '1' => '1.8.3'
            ).merge(
              '1.0' => '1.0.3',
              '1.0.x' => '1.0.3',
              '1.1.x' => '1.1.2',
              '1.2' => '1.2.2',
              '1.2.x' => '1.2.2',
              '1.3.x' => '1.3.3',
              '1.4.x' => '1.4.3',
              '1.5.x' => '1.5.4',
              '1.6.x' => '1.6.4',
              '1.7.x' => '1.7.6',
              '1.8.x' => '1.8.3',
              '1.x' => '1.8.3',
              '1.x.x' => '1.8.3'
            ).map { |k, v| "#{k}:#{v}" }.join(',')
          )
        ),
        internal_ruby_regex: ENV.fetch(
          'TRAVIS_BUILD_INTERNAL_RUBY_REGEX',
          '^ruby-(2\.[0-2]\.[0-9]|1\.9\.3)'
        ),
        librato: {
          email: ENV.fetch(
            'TRAVIS_BUILD_LIBRATO_EMAIL', ENV.fetch('LIBRATO_EMAIL', '')
          ),
          source: ENV.fetch(
            'TRAVIS_BUILD_LIBRATO_SOURCE', ENV.fetch('LIBRATO_SOURCE', '')
          ),
          token: ENV.fetch(
            'TRAVIS_BUILD_LIBRATO_TOKEN', ENV.fetch('LIBRATO_TOKEN', '')
          ),
        },
        sentry_dsn: ENV.fetch(
          'TRAVIS_BUILD_SENTRY_DSN', ENV.fetch('SENTRY_DSN', '')
        ),
        update_glibc: ENV.fetch(
          'TRAVIS_BUILD_UPDATE_GLIBC',
          ENV.fetch('TRAVIS_UPDATE_GLIBC', ENV.fetch('UPDATE_GLIBC', ''))
        )
      )

      default(
        access: %i(key),
      )
    end
  end
end
