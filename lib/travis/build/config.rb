require 'hashr'
require 'travis/config'

module Travis
  module Build
    class Config < Travis::Config
      extend Hashr::Env
      self.env_namespace = 'travis_build'

      def go_version_aliases_hash
        @go_version_aliases_hash ||= version_aliases_hash('go')
      end

      def ghc_version_aliases_hash
        @ghc_version_aliases_hash ||= version_aliases_hash('ghc')
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
        cabal_default: ENV.fetch('TRAVIS_BUILD_CABAL_DEFAULT', '2.0'),
        auth_disabled: ENV.fetch('TRAVIS_BUILD_AUTH_DISABLED', ''),
        enable_debug_tools: ENV.fetch(
          'TRAVIS_BUILD_ENABLE_DEBUG_TOOLS',
          ENV.fetch('TRAVIS_ENABLE_DEBUG_TOOLS', '')
        ),
        etc_hosts_pinning: ENV.fetch(
          'TRAVIS_BUILD_ETC_HOSTS_PINNING', ENV.fetch('ETC_HOSTS_PINNING', '')
        ),
        ghc_default: ENV.fetch('TRAVIS_BUILD_GHC_DEFAULT', '7.10.3'),
        gimme: {
          url: ENV.fetch(
            'TRAVIS_BUILD_GIMME_URL',
            'https://raw.githubusercontent.com/travis-ci/gimme/v1.2.0/gimme'
          )
        },
        go_version: ENV.fetch('TRAVIS_BUILD_GO_VERSION', '1.9'),
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

      private

        def version_aliases_hash(name)
          JSON.parse(
            File.read(
              File.expand_path(
                "../../../../public/version-aliases/#{name}.json",
                __FILE__
              )
            ).untaint
          )
        end
    end
  end
end
