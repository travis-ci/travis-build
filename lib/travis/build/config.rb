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
        app_host: '',
        apt_package_whitelist: {
          precise: '',
          trusty: ''
        },
        apt_source_whitelist: {
          precise: '',
          trusty: ''
        },
        apt_whitelist_skip: '',
        ghc_default: '7.8.4',
        gimme: {
          force_reinstall: '',
          url: 'https://raw.githubusercontent.com/travis-ci/gimme/v1.0.0/gimme'
        },
        go_version: '1.7.4',
        go_version_aliases: {
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

      default(
        access: %i(key),
      )
    end
  end
end
