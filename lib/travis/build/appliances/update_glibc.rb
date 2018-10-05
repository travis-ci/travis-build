require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class UpdateGlibc < Base
        def apply?
          super && Travis::Build.config.update_glibc?
        end

        def apply
          return unless data.disable_sudo?
          sh.if '${TRAVIS_OS_NAME} == linux && ${TRAVIS_DIST} == precise' do
            sh.fold "fix.CVE-2015-7547" do
              sh.echo 'Forcing update of libc6', ansi: :yellow
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
