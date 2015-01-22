require 'travis/build/addons/base'

module Travis
  module Build
    class Addons
      class AptPackages < Base
        SUPER_USER_SAFE = true

        class << self
          def whitelist
            @whitelist ||= load_whitelist
          end

          private

          def load_whitelist
            require 'faraday'
            response = Faraday.get(ENV['TRAVIS_BUILD_APT_WHITELIST'])
            response.body.to_s.split.map(&:strip).sort.uniq
          rescue => e
            warn e
            []
          end
        end

        def after_prepare
          sh.fold 'apt_packages' do
            sh.echo "Installing APT Packages (BETA)", ansi: :yellow

            whitelisted = []
            disallowed = []

            config.each do |package|
              if whitelist.include?(package)
                whitelisted << package
              else
                disallowed << package
              end
            end

            unless disallowed.empty?
              sh.echo "Disallowing packages: #{disallowed.join(', ')}", ansi: :red
              sh.echo 'If you require these packages, please review the package '
                      'approval process at:'
              sh.echo '    https://github.com/travis-ci/apt-package-whitelist#package-approval-process'
            end

            unless whitelisted.empty?
              sh.export 'DEBIAN_FRONTEND', 'noninteractive', echo: true
              sh.cmd "sudo -E apt-get -yqq update", echo: true, timing: true
              sh.cmd 'sudo -E apt-get -yq --no-install-suggests --no-install-recommends ' \
                     "install #{whitelisted.join(' ')}", echo: true, timing: true
            end
          end
        end

        private

          def config
            Array(super)
          end

          def whitelist
            ::Travis::Build::Addons::AptPackages.whitelist
          end
      end
    end
  end
end
