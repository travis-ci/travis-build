require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class ShowSystemInfo < Base
        def apply
          sh.fold 'system_info' do
            header
            sh.if "-f #{info_file}" do
              sh.cmd "cat #{info_file}"
            end
          end
          sh.newline
        end

        private

          def header
            sh.echo 'Build system information', ansi: :yellow
            [:language, :group, :dist].each do |attr|
              sh.echo "Build script #{attr}: #{data.send(attr)}"
            end
          end

          def info_file
            '/usr/share/travis/system_info'
          end
      end
    end
  end
end
