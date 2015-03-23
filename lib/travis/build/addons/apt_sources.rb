require 'travis/build/addons/base'

module Travis
  module Build
    class Addons
      class AptSources < Base
        SUPER_USER_SAFE = true

        class << self
          def whitelist
            @whitelist ||= load_whitelist
          end

          private

          def load_whitelist
            require 'faraday'
            response = Faraday.get(ENV['TRAVIS_BUILD_APT_SOURCE_WHITELIST'])
            JSON.parse(response.body.to_s)
          rescue => e
            warn e
            {}
          end
        end

        def after_prepare
          sh.fold 'apt_sources' do
            sh.echo "Adding APT Sources (BETA)", ansi: :yellow

            whitelisted = []
            disallowed = []

            config.each do |source_alias|
              if whitelist.keys.include?(source_alias)
                whitelisted << whitelist[source_alias]
              else
                disallowed << source_alias
              end
            end

            unless disallowed.empty?
              sh.echo "Disallowing sources: #{disallowed.join(', ')}", ansi: :red
              sh.echo 'If you require these sources, please review the source ' \
                      'approval process at: ' \
                      'https://github.com/travis-ci/apt-source-whitelist#source-approval-process'
            end

            unless whitelisted.empty?
              sh.export 'DEBIAN_FRONTEND', 'noninteractive', echo: true
              whitelisted.each do |source|
                sourceline, key_url = source
                sh.cmd "curl -sSL #{key_url.inspect} | sudo -E apt-key add -", echo: true, assert: true, timing: true if key_url
                sh.cmd "sudo -E apt-add-repository -y #{sourceline.inspect}", echo: true, assert: true, timing: true
              end
              sh.cmd "sudo -E apt-get -yq update &>> ~/apt-get-update.log", echo: true, timing: true
            end
          end
        end

        private

          def config
            Array(super)
          end

          def whitelist
            ::Travis::Build::Addons::AptSources.whitelist
          end
      end
    end
  end
end
