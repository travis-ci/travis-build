require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class UpdateGlibc < Base
        def apply?
          !Travis::Build.config.update_glibc.empty?
        end

        def apply
          return unless data.disable_sudo?
          sh.if "-n $(command -v lsb_release) && $(lsb_release -cs) = 'precise'" do
            sh.fold "fix.CVE-2015-7547" do
              sh.export 'DEBIAN_FRONTEND', 'noninteractive'
              sh.cmd 'travis_apt_get_update'
              sh.if '${TRAVIS_OS_NAME} != darwin' do
                sh.cmd 'sudo -E apt-get -yq --no-install-suggests --no-install-recommends --force-yes install libc6'
              end
            end
          end
        end

      end
    end
  end
end

