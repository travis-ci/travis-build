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
              '1' => '1.7.4',
              '1.0' => '1.0.3',
              '1.0.x' => '1.0.3',
              '1.1.x' => '1.1.2',
              '1.2' => '1.2.2',
              '1.2.x' => '1.2.2',
              '1.3.x' => '1.3.3',
              '1.4.x' => '1.4.3',
              '1.5.x' => '1.5.4',
              '1.6.x' => '1.6.3',
              '1.7.x' => '1.7.4',
              '1.x' => '1.7.4',
              '1.x.x' => '1.7.4'
            }.map { |k, v| "#{k}:#{v}" }.join(',')
          )
        )
      )

      default(
        access: %i(key),
      )
    end
  end
end
