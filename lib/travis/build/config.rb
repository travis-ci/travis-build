require 'uri'

require 'hashr'
require 'travis/config'

require 'core_ext/string/to_bool'

module Travis
  module Build
    class Config < Travis::Config
      extend Hashr::Env
      self.env_namespace = 'travis_build'

      def ghc_version_aliases_hash
        @ghc_version_aliases_hash ||= version_aliases_hash('ghc')
      end

      def sc_data
        @sc_data ||= JSON.parse(
          Travis::Build.top.join('tmp/sc_data.json').read.output_safe
        )
      end

      define(
        api_token: ENV.fetch(
          'TRAVIS_BUILD_API_TOKEN', ENV.fetch('API_TOKEN', '')
        ),
        app_host: ENV.fetch('TRAVIS_APP_HOST', ''),
        apt_mirrors: {
          ec2: ENV.fetch(
            'TRAVIS_BUILD_APT_MIRRORS_EC2',
            'http://us-east-1.ec2.archive.ubuntu.com/ubuntu/'
          ),
          gce: ENV.fetch(
            'TRAVIS_BUILD_APT_MIRRORS_GCE',
            'http://us-central1.gce.archive.ubuntu.com/ubuntu/'
          ),
          packet: ENV.fetch(
            'TRAVIS_BUILD_APT_MIRRORS_PACKET',
            'http://archive.ubuntu.com/ubuntu/'
          ),
          unknown: ENV.fetch(
            'TRAVIS_BUILD_APT_MIRRORS_UNKNOWN',
            'http://archive.ubuntu.com/ubuntu/'
          )
        },
        apt_package_safelist: {
          precise: ENV.fetch('TRAVIS_BUILD_APT_PACKAGE_SAFELIST_PRECISE', ''),
          trusty: ENV.fetch('TRAVIS_BUILD_APT_PACKAGE_SAFELIST_TRUSTY', ''),
          xenial: ENV.fetch('TRAVIS_BUILD_APT_PACKAGE_SAFELIST_XENIAL', ''),
          bionic: ENV.fetch('TRAVIS_BUILD_APT_PACKAGE_SAFELIST_BIONIC', ''),
        },
        apt_proxy: ENV.fetch('TRAVIS_BUILD_APT_PROXY', ''),
        apt_source_alias_list: {
          precise: ENV.fetch('TRAVIS_BUILD_APT_SOURCE_ALIAS_LIST_PRECISE', ''),
          trusty: ENV.fetch('TRAVIS_BUILD_APT_SOURCE_ALIAS_LIST_TRUSTY', ''),
          xenial: ENV.fetch('TRAVIS_BUILD_APT_SOURCE_ALIAS_LIST_XENIAL', ''),
          bionic: ENV.fetch('TRAVIS_BUILD_APT_SOURCE_ALIAS_LIST_BIONIC', ''),
        },
        apt_source_alias_list_key_url_template: ENV.fetch(
          'TRAVIS_BUILD_APT_SOURCE_ALIAS_LIST_KEY_URL_TEMPLATE',
          'https://%{app_host}/files/gpg/%{source_alias}.asc'
        ),
        apt_safelist_skip: ENV.fetch('TRAVIS_BUILD_APT_SAFELIST_SKIP', '').to_bool,
        apt_load_source_alias_list: ENV.fetch('TRAVIS_BUILD_APT_LOAD_SOURCE_ALIAS_LIST', 'true').to_bool,
        auth_disabled: ENV.fetch('TRAVIS_BUILD_AUTH_DISABLED', '').to_bool,
        cabal_default: ENV.fetch('TRAVIS_BUILD_CABAL_DEFAULT', '2.0'),
        enable_debug_tools: ENV.fetch(
          'TRAVIS_BUILD_ENABLE_DEBUG_TOOLS',
          ENV.fetch('TRAVIS_ENABLE_DEBUG_TOOLS', '')
        ),
        enable_infra_detection: ENV.fetch(
          'TRAVIS_BUILD_ENABLE_INFRA_DETECTION', ''
        ).to_bool,
        etc_hosts_pinning: ENV.fetch(
          'TRAVIS_BUILD_ETC_HOSTS_PINNING', ENV.fetch('ETC_HOSTS_PINNING', '')
        ),
        ghc_default: ENV.fetch('TRAVIS_BUILD_GHC_DEFAULT', '7.10.3'),
        gimme: {
          url: ENV.fetch(
            'TRAVIS_BUILD_GIMME_URL',
            'https://raw.githubusercontent.com/travis-ci/gimme/v1.5.3/gimme'
          )
        },
        go_version: ENV.fetch('TRAVIS_BUILD_GO_VERSION', '1.11.x'),
        internal_ruby_regex: ENV.fetch(
          'TRAVIS_BUILD_INTERNAL_RUBY_REGEX',
          '^ruby-(2\.[0-4]\.[0-9]|1\.9\.3)'
        ),
        lang_archive_host: ENV.fetch('TRAVIS_LANGUAGE_ARCHIVE_HOST', 's3'),
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
        maven_central_mirror: ENV.fetch('TRAVIS_MAVEN_CENTRAL_MIRROR', ''),
        network: {
          wait_retries: Integer(ENV.fetch(
            'TRAVIS_BUILD_NETWORK_WAIT_RETRIES',
            ENV.fetch('NETWORK_WAIT_RETRIES', '20')
          )),
          check_urls: ENV.fetch(
            'TRAVIS_BUILD_NETWORK_CHECK_URLS',
            ENV.fetch(
              'NETWORK_CHECK_URLS',
              'http://%{app_host}/empty.txt?job_id=%{job_id}&repo=%{repo}'
            )
          ).split(',').map { |s| URI.unescape(s.strip) }
        },
        redis: { url: 'redis://localhost:6379' },
        sentry_dsn: ENV.fetch(
          'TRAVIS_BUILD_SENTRY_DSN', ENV.fetch('SENTRY_DSN', '')
        ),
        tainted_node_logging_enabled: false,
        trace_command: ENV.fetch('TRACE_COMMAND', 'GIT_TRACE=true'),
        trace_git_commands_owners: ENV.fetch('TRACE_GIT_COMMANDS_OWNERS', ''),
        trace_git_commands_slugs: ENV.fetch('TRACE_GIT_COMMANDS_SLUGS', ''),
        update_glibc: ENV.fetch(
          'TRAVIS_BUILD_UPDATE_GLIBC',
          ENV.fetch('TRAVIS_UPDATE_GLIBC', ENV.fetch('UPDATE_GLIBC', 'false'))
        ).to_bool,
        windows_langs: ENV.fetch(
          'TRAVIS_WINDOWS_LANGS',
          %w(
            bash
            csharp
            generic
            go
            julia
            minimal
            node_js
            powershell
            rust
            script
            sh
            shell
          ).join(",")
        ).split(/,/),
        dump_backtrace: ENV.fetch(
          'TRAVIS_BUILD_DUMP_BACKTRACE', ENV.fetch('DUMP_BACKTRACE', 'false')
        ).to_bool,
        wait_for_network_check: ENV.fetch('TRAVIS_WAIT_FOR_NETWORK_CHECK', 'true').to_bool
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
            ).output_safe
          )
        end
    end
  end
end
