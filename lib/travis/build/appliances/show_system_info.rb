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
            return if heroku_slug_commit.empty?
            sh.echo "travis-build version: #{heroku_slug_commit}"
          end

          def show_system_info_file
            sh.if "-f #{info_file}" do
              sh.cmd "cat #{info_file}"
            end
            sh.if "-f #{secondary_info_file}" do
              sh.cmd "cat #{secondary_info_file}"
            end
          end

          def info_file
            '/usr/share/travis/system_info'
          end

          def secondary_info_file
            '/usr/local/travis/system_info'
          end

          def heroku_slug_commit
            @heroku_slug_commit ||= ENV['HEROKU_SLUG_COMMIT'].to_s.output_safe
          end
      end
    end
  end
end
