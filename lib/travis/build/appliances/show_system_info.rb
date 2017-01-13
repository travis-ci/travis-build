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
            advertise_system_info_addon
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
          end

          def show_travis_build_version
            if ENV['HEROKU_SLUG_COMMIT']
              sh.echo "travis-build version: #{ENV['HEROKU_SLUG_COMMIT']}".untaint
            end
          end

          def show_system_info_file
            sh.if "-f #{info_file}" do
              sh.echo "Info file: #{info_file}"
            end
            sh.if "-f #{info_json_file}" do
              sh.echo "Info JSON file: #{info_json_file}"
            end
          end

          def advertise_system_info_addon
            sh.echo(
              %(Extended system info available via the "system_info" addon),
              ansi: :yellow
            )
          end

          def info_file
            '/usr/share/travis/system_info'
          end

          def info_json_file
            '/usr/share/travis/system_info.json'
          end
      end
    end
  end
end
