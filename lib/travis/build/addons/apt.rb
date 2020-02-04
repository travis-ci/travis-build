require 'travis/build/addons/base'
require 'shellwords'

module Travis
  module Build
    class Addons
      class Apt < Base
        SUPER_USER_SAFE = true
        SUPPORTED_OPERATING_SYSTEMS = [
          /^linux.*/
        ].freeze
        SUPPORTED_DISTS = %w(
          precise
          trusty
          xenial
          bionic
        ).freeze

        attr_reader :safelisted, :disallowed_while_sudo

        class << self
          def package_safelists
            @package_safelists ||= load_package_safelists
          end

          def source_alias_lists
            @source_alias_lists ||= load_source_alias_lists
          end

          private

          def load_package_safelists(dists = SUPPORTED_DISTS)
            require 'faraday'
            loaded = { unset: [] }.merge(Hash[dists.map { |dist| [dist.to_sym, []] }])
            dists.each do |dist|
              response = fetch_package_safelist(dist)
              loaded[dist.to_sym] = response.split.map(&:strip).sort.uniq
            end
            loaded
          rescue => e
            warn e unless ENV['ENV'] == 'test'
            loaded
          end

          def load_source_alias_lists(dists = SUPPORTED_DISTS)
            require 'faraday'
            loaded = { unset: {} }.merge(Hash[dists.map { |dist| [dist.to_sym, {}] }])
            dists.each do |dist|
              response = fetch_source_alias_list(dist)
              entries = JSON.parse(response)
              loaded[dist.to_sym] = Hash[entries.reject { |e| !e.key?('alias') }.map { |e| [e.fetch('alias'), e] }]
            end
            loaded
          rescue => e
            warn e unless ENV['ENV'] == 'test'
            loaded
          end

          def fetch_package_safelist(dist)
            Faraday.get(package_safelist_url(dist)).body.to_s
          end

          def fetch_source_alias_list(dist)
            Faraday.get(source_alias_list_url(dist)).body.to_s
          end

          def package_safelist_url(dist)
            Travis::Build.config.apt_package_safelist[dist.downcase].to_s
          end

          def source_alias_list_url(dist)
            Travis::Build.config.apt_source_alias_list[dist.downcase].to_s
          end
        end

        def before_prepare?
          SUPPORTED_OPERATING_SYSTEMS.any? do |os_match|
            data[:config][:os].to_s =~ os_match
          end && SUPPORTED_DISTS.include?(data[:config][:dist].to_s)
        end

        def before_prepare
          sh.fold('apt') do
            add_apt_sources unless config_sources.empty?
            if config[:update] || !config_sources.empty? || !config_packages.empty?
              sh.cmd 'travis_apt_get_update', retry: true, echo: true, timing: true
            end
            add_apt_packages unless config_packages.empty?
          end
        end

        def skip_safelist?
          Travis::Build.config.apt_safelist_skip?
        end

        def load_alias_list?
          Travis::Build.config.apt_load_source_alias_list?
        end

        def before_configure?
          config[:config] && config[:config][:retries]
        end

        def before_configure
          sh.echo "Configuring default apt-get retries", ansi: :yellow
          sh.if '-d ${TRAVIS_ROOT}/var/lib/apt/lists && -n $(command -v apt-get)' do
            tmp_dest = '${TRAVIS_TMPDIR}/99-travis-build-retries'
            sh.file tmp_dest, <<~APT_CONF
              Acquire {
                ForceIPv4 "1";
                Retries "5";
                https {
                  Timeout "30";
                };
              };
            APT_CONF
            sh.cmd "sudo mv #{tmp_dest} ${TRAVIS_ROOT}/etc/apt/apt.conf.d"
          end
        end

        def config
          @config ||= Hash(super)
        end

        private

          def add_apt_sources
            sh.echo "Adding APT Sources", ansi: :yellow

            @safelisted = []
            disallowed = []
            @disallowed_while_sudo = []

            config_sources.each do |src|
              if !load_alias_list?
                sh.echo "Skipping loading APT source aliases list", ansi: :yellow
                add_to_safelisted src
                next
              end

              if source = source_alias_lists[config_dist][src[:name]]
                if source.respond_to?(:[]) && source['sourceline']
                  safelisted << source.clone
                else
                  sh.echo "'sourceline' is missing in the alias #{src[:name]}", ansi: :yellow
                  sh.echo Shellwords.escape(src[:name].inspect)
                end
              elsif !data.disable_sudo? || skip_safelist?
                add_to_safelisted src
              elsif source.nil?
                disallowed << src[:name]
              end
            end

            unless disallowed.empty?
              sh.echo "Disallowing sources: #{disallowed.map { |source| Shellwords.escape(source) }.join(', ')}", ansi: :red
              sh.echo 'If you require these sources, please use `sudo: required` in your `.travis.yml` to manage APT sources.'
            end

            unless disallowed_while_sudo.empty?
              sh.echo "Disallowing sources: #{disallowed_while_sudo.map { |source| Shellwords.escape(source) }.join(', ')}", ansi: :red
              sh.echo "To add unlisted APT sources, follow instructions in " \
                "https://docs.travis-ci.com/user/installing-dependencies#Installing-Packages-with-the-APT-Addon"
            end

            unless safelisted.empty?
              safelisted.each do |source|
                sourceline = source['sourceline'].output_safe
                if sourceline.start_with?('ppa:')
                  sh.cmd "sudo -E apt-add-repository -y #{sourceline.inspect}", echo: true, assert: true, timing: true
                else
                  sh.cmd "curl -sSL \"#{safelisted_source_key_url(source)}\" | sudo -E apt-key add -", echo: true, assert: true, timing: true
                  # Avoid adding deb-src lines to work around https://bugs.launchpad.net/ubuntu/+source/software-properties/+bug/987264
                  sh.cmd "echo #{sourceline.inspect} | sudo tee -a ${TRAVIS_ROOT}/etc/apt/sources.list >/dev/null", echo: true, assert: true, timing: true
                end
              end
            end
          end

          def add_to_safelisted(src)
            if src.has_key?(:sourceline)
              safelisted << {
                'sourceline' => src[:sourceline],
                'key_url' => src[:key_url]
              }
            elsif src.keys == [:key_url]
              sh.echo "'sourceline' key missing:", ansi: :yellow
              sh.echo Shellwords.escape(src.inspect)
            else
              disallowed_while_sudo << src[:name]
            end
          end

          def add_apt_packages
            sh.echo "Installing APT Packages", ansi: :yellow

            safelisted, disallowed = config_packages.partition { |pkg| package_safelisted?(package_safelists[config_dist] || [], pkg) }

            unless disallowed.empty?
              sh.echo "Disallowing packages: #{disallowed.map { |package| Shellwords.escape(package) }.join(', ')}", ansi: :red
              sh.echo 'If you require these packages, please review the package ' \
                'approval process at: ' \
                'https://github.com/travis-ci/apt-package-safelist#package-approval-process'
            end

            unless safelisted.empty?
              if safelisted.any? {|pkg| pkg =~ /^postgresql/}
                stop_postgresql
              end

              sh.raw bash('travis_apt_get_options')
              command = 'sudo -E apt-get -yq --no-install-suggests --no-install-recommends ' \
                "$(travis_apt_get_options) install #{safelisted.join(' ')}"
              sh.cmd command, echo: true, timing: true

              sh.raw "result=$?"
              sh.if '$result -ne 0' do
                sh.fold 'apt-get.diagnostics' do
                  sh.echo "apt-get install failed", ansi: :red
                  sh.cmd 'cat ${TRAVIS_HOME}/apt-get-update.log', echo: true
                end
                sh.raw "TRAVIS_CMD='#{command}'"
                sh.raw "travis_assert $result"
              end
            end
          end

          def config_sources
            @config_sources ||= Array([config[:sources]]).flatten.compact.map do |src|
              src.is_a?(String) ? { name: src } : src
            end
          rescue TypeError => e
            if e.message =~ /no implicit conversion of Symbol into Integer/
              raise Travis::Build::AptSourcesConfigError.new
            end
          end

          def config_packages
            @config_packages ||= Array(config[:packages]).flatten.compact
          rescue TypeError => e
            if e.message =~ /no implicit conversion of Symbol into Integer/
              raise Travis::Build::AptPackagesConfigError.new
            end
          end

          def config_dist
            (data.config[:dist] || :unset).to_sym
          end

          def package_safelisted?(list, pkg)
            list.include?(pkg) || !data.disable_sudo? || skip_safelist?
          end

          def package_safelists
            ::Travis::Build::Addons::Apt.package_safelists
          end

          def source_alias_lists
            ::Travis::Build::Addons::Apt.source_alias_lists
          end

          def safelisted_source_key_url(source)
            tmpl = Travis::Build.config.apt_source_alias_list_key_url_template.to_s.output_safe
            if source['key_url'] && (!data.disable_sudo? || skip_safelist?)
              tmpl = source['key_url']
            end
            format(
              tmpl.to_s,
              source_alias: source['alias'] || 'travis-security',
              app_host: Travis::Build.config.app_host.to_s.strip
            ).output_safe
          end

          def stop_postgresql
            sh.echo "PostgreSQL package is detected. Stopping postgresql service. See https://github.com/travis-ci/travis-ci/issues/5737 for more information.", ansi: :yellow
            sh.if '"${TRAVIS_INIT}" == systemd' do
              sh.cmd 'sudo systemctl stop postgresql', echo: true
            end
            sh.else do
              sh.cmd 'sudo service postgresql stop', echo: true
            end
          end
      end
    end
  end
end
