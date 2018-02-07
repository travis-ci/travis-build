require 'travis/build/appliances/base'
require 'shellwords'

module Travis
  module Build
    module Appliances
      class ShowSystemInfo < Base
        def apply
          sh.fold 'system_info' do
            header
            show_travis_build_version
            show_system_info_file
          end
          sh.newline
        end

        private

          def header
            sh.echo 'Build system information', ansi: :yellow
            [:language, :group, :dist].each do |name|
              value = data.send(name)
              sh.echo "Build #{name}: #{Shellwords.escape(value)}" if value
            end
            sh.echo "Build id: #{Shellwords.escape(data.build[:id])}"
            sh.echo "Job id: #{Shellwords.escape(data.job[:id])}"
            sh.echo "Runtime kernel version: $(uname -r)"
          end

          def show_travis_build_version
            if ENV['HEROKU_SLUG_COMMIT']
              sh.echo "travis-build version: #{ENV['HEROKU_SLUG_COMMIT']}".untaint
            end
          end

          def show_system_info_file
            sh.if "-f #{info_file}" do
              sh.cmd "cat #{info_file}"
            end
          end

          def info_file
            '/usr/share/travis/system_info'
          end
      end
    end
  end
end
