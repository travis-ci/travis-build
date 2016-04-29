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
            @package_whitelist ||= load_package_whitelist.reject { |w| w =~ regex_detecting_regex }
          end

          def package_whitelist_regexes
            @package_whitelist_regexes ||= load_package_whitelist
              .select { |w| w =~ regex_detecting_regex }
              .map { |w| Regexp.compile(w) rescue nil }
              .compact
          end

          def source_whitelist
            @source_whitelist ||= load_source_whitelist
          end

          def reset_caches
            @package_whitelist =
              @package_whitelist_regexes =
              @source_whitelist =
              @loaded_package_whitelist = nil
          end

          private

          def load_package_whitelist
            require 'faraday'
            @loaded_package_whitelist ||= begin
              response = fetch_package_whitelist
              response.split.map(&:strip).sort.uniq
            end
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

          def regex_detecting_regex
            # Detects only the subset of regexes supported in the apt packages whitelist
            /[*?+()]/
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
              if package_whitelist.include?(package) ||
                 package_whitelist_regexes.detect { |w| w.match(package) }
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
              if whitelisted.any? {|pkg| pkg =~ /^postgresql/}
                stop_postgresql
              end

              sh.export 'DEBIAN_FRONTEND', 'noninteractive', echo: true
              sh.cmd "sudo -E apt-get -yq update &>> ~/apt-get-update.log", echo: true, timing: true
              command = 'sudo -E apt-get -yq --no-install-suggests --no-install-recommends ' \
                "--force-yes install #{whitelisted.join(' ')}"
              sh.cmd command, echo: true, timing: true
              sh.raw "result=$?"
              sh.if '$result -ne 0' do
                sh.fold 'apt-get.diagnostics' do
                  sh.echo "apt-get install failed", ansi: :red
                  sh.cmd 'cat ~/apt-get-update.log', echo: true
                end
                sh.raw "TRAVIS_CMD='#{command}'"
                sh.raw "travis_assert $result"
              end
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

          def package_whitelist_regexes
            ::Travis::Build::Addons::Apt.package_whitelist_regexes
          end

          def source_whitelist
            ::Travis::Build::Addons::Apt.source_whitelist
          end

          def stop_postgresql
            sh.echo "PostgreSQL package is detected. Stopping postgresql service. See https://github.com/travis-ci/travis-ci/issues/5737 for more information.", ansi: :yellow
            sh.cmd "sudo service postgresql stop", echo: true
          end
      end
    end
  end
end
