require 'travis/build/addons/base'

module Travis
  module Build
    class Addons
      class AptPackages < Base
        SUPER_USER_SAFE = true

        def after_prepare
          sh.fold 'apt_packages' do
            sh.echo "Installing APT Packages (BETA)", ansi: :yellow

            whitelisted = []
            config.each do |package|
              if whitelist.include?(package)
                whitelisted << package
              else
                sh.echo "Ignoring unknown/disallowed package #{package.inspect}"
              end
            end

            unless whitelisted.empty?
              sh.export 'DEBIAN_FRONTEND', 'noninteractive', echo: true
              sh.cmd "sudo -E apt-get -yq update", echo: true, timing: true
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
            @whitelist ||= ENV['TRAVIS_BUILD_APT_WHITELIST'].to_s.split(/\s*,\s*/)
          end
      end
    end
  end
end
