require 'travis/build/addons/base'

module Travis
  module Build
    class Addons
      class AptPackages < Base
        SUPER_USER_SAFE = true

        def after_prepare
          sh.echo "Installing APT Packages (BETA)", ansi: :yellow
          sh.fold 'apt_packages.0' do
            whitelisted = []
            config.each do |package|
              if whitelist.include?(package)
                whitelisted << package
              else
                sh.echo "Ignoring unknown/disallowed package #{package.inspect}"
              end
            end

            sh.export 'DEBIAN_FRONTEND', 'noninteractive', echo: true
            sh.cmd "apt-get -yq install #{whitelisted.join(' ')}", echo: true, timing: true
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
