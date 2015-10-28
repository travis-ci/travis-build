require 'travis/build/addons/base'
require 'shellwords'

module Travis
  module Build
    class Addons
      class Apt < Base
        SUPER_USER_SAFE = true
        SUPPORTED_OPERATING_SYSTEMS = %w(
          linux
        ).freeze

        class << self
          def package_whitelist
            @package_whitelist ||= load_package_whitelist
          end

          def source_whitelist
            @source_whitelist ||= load_source_whitelist
          end

          private

          def load_package_whitelist
            require 'faraday'
            response = fetch_package_whitelist
            response.split.map(&:strip).sort.uniq
          rescue => e
            warn e
            []
          end

          def load_source_whitelist
            require 'faraday'
            response = fetch_source_whitelist
            entries = JSON.parse(response)
            Hash[entries.reject { |e| !e.key?('alias') }.map { |e| [e.fetch('alias'), e] }]
          rescue => e
            warn e
            {}
          end

          def fetch_package_whitelist
            Faraday.get(package_whitelist_url).body.to_s
          end

          def fetch_source_whitelist
            Faraday.get(source_whitelist_url).body.to_s
          end

          def package_whitelist_url
            ENV['TRAVIS_BUILD_APT_PACKAGE_WHITELIST'] || ENV['TRAVIS_BUILD_APT_WHITELIST']
          end

          def source_whitelist_url
            ENV['TRAVIS_BUILD_APT_SOURCE_WHITELIST']
          end
        end

        def before_prepare?
          SUPPORTED_OPERATING_SYSTEMS.include?(data[:config][:os].to_s)
        end

        def before_prepare
          sh.fold('apt') do
            add_apt_sources unless config_sources.empty?
            add_apt_packages unless config_packages.empty?
          end
        end

        private

          def add_apt_sources
            sh.echo "Adding APT Sources (BETA)", ansi: :yellow

            whitelisted = []
            disallowed = []

            config_sources.each do |source_alias|
              source = source_whitelist[source_alias]
              whitelisted << source.clone if source && source['sourceline']
              disallowed << source_alias if source.nil?
            end

            unless disallowed.empty?
              sh.echo "Disallowing sources: #{disallowed.map { |source| Shellwords.escape(source) }.join(', ')}", ansi: :red
              sh.echo 'If you require these sources, please review the source ' \
                'approval process at: ' \
                'https://github.com/travis-ci/apt-source-whitelist#source-approval-process'
            end

            unless whitelisted.empty?
              sh.export 'DEBIAN_FRONTEND', 'noninteractive', echo: true
              whitelisted.each do |source|
                sh.cmd "curl -sSL #{source['key_url'].untaint.inspect} | sudo -E apt-key add -", echo: true, assert: true, timing: true if source['key_url']
                if source['sourceline'].start_with? 'ppa:'
                  sh.cmd "sudo -E apt-add-repository -y #{source['sourceline'].untaint.inspect}", echo: true, assert: true, timing: true
                else
                  # Avoid adding deb-src lines to work around https://bugs.launchpad.net/ubuntu/+source/software-properties/+bug/987264
                  sh.cmd "echo #{source['sourceline'].untaint.inspect} | sudo tee -a /etc/apt/sources.list > /dev/null", echo: true, assert: true, timing: true
                end
              end
            end
          end

          def add_apt_packages
            sh.echo "Installing APT Packages (BETA)", ansi: :yellow

            whitelisted = []
            disallowed = []

            config_packages.each do |package|
              if package_whitelist.include?(package)
                whitelisted << package
              else
                disallowed << package
              end
            end

            unless disallowed.empty?
              sh.echo "Disallowing packages: #{disallowed.map { |package| Shellwords.escape(package) }.join(', ')}", ansi: :red
              sh.echo 'If you require these packages, please review the package ' \
                'approval process at: ' \
                'https://github.com/travis-ci/apt-package-whitelist#package-approval-process'
            end

            unless whitelisted.empty?
              sh.export 'DEBIAN_FRONTEND', 'noninteractive', echo: true
              sh.cmd "sudo -E apt-get -yq update &>> ~/apt-get-update.log", echo: true, timing: true
              sh.cmd 'sudo -E apt-get -yq --no-install-suggests --no-install-recommends ' \
                "--force-yes install #{whitelisted.join(' ')}", echo: true, timing: true
            end
          end

          def config
            @config ||= Hash(super)
          end

          def config_sources
            @config_sources ||= Array(config[:sources]).flatten.compact
          end

          def config_packages
            @config_packages ||= Array(config[:packages]).flatten.compact
          end

          def package_whitelist
            ::Travis::Build::Addons::Apt.package_whitelist
          end

          def source_whitelist
            ::Travis::Build::Addons::Apt.source_whitelist
          end
      end
    end
  end
end
