require 'hashr'
require 'travis/config'

module Travis
  module Build
    class Config < Travis::Config
      extend Hashr::Env
      self.env_namespace = 'travis_build'

      def go_version_aliases_hash
        @go_version_aliases_hash ||= begin
          {}.tap do |aliases|
            go_version_aliases.untaint.split(',').each do |v|
              key, value = v.strip.split(':', 2)
              next if key.nil? || value.nil?
              aliases[key] = value
            end
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
        auth_disabled: ENV.fetch('TRAVIS_BUILD_AUTH_DISABLED', ''),
        enable_debug_tools: ENV.fetch(
          'TRAVIS_BUILD_ENABLE_DEBUG_TOOLS',
          ENV.fetch('TRAVIS_ENABLE_DEBUG_TOOLS', '')
        ),
        etc_hosts_pinning: ENV.fetch(
          'TRAVIS_BUILD_ETC_HOSTS_PINNING', ENV.fetch('ETC_HOSTS_PINNING', '')
        ),
        ghc_default: ENV.fetch('TRAVIS_BUILD_GHC_DEFAULT', '7.8.4'),
        gimme: {
          force_reinstall: ENV.fetch('TRAVIS_BUILD_GIMME_FORCE_REINSTALL', ''),
          url: ENV.fetch(
            'TRAVIS_BUILD_GIMME_URL',
            'https://raw.githubusercontent.com/travis-ci/gimme/v1.0.0/gimme'
          )
        },
        go_version: ENV.fetch('TRAVIS_BUILD_GO_VERSION', '1.7.4'),
        go_version_aliases: ENV.fetch(
          'TRAVIS_BUILD_GO_VERSION_ALIASES', (
            {
              '1' => '1.8',
              '1.0' => '1.0.3',
              '1.0.x' => '1.0.3',
              '1.1.x' => '1.1.2',
              '1.2' => '1.2.2',
              '1.2.x' => '1.2.2',
              '1.3.x' => '1.3.3',
              '1.4.x' => '1.4.3',
              '1.5.x' => '1.5.4',
              '1.6.x' => '1.6.4',
              '1.7.x' => '1.7.5',
              '1.8.x' => '1.8',
              '1.x' => '1.8',
              '1.x.x' => '1.8'
            }.map { |k, v| "#{k}:#{v}" }.join(',')
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
