require 'travis/build/appliances/base'
require 'travis/build/git'

module Travis
  module Build
    module Appliances
      class SetupFilter < Base
        DEFAULT_SETTING = true

        def apply?
          enabled? and secrets.any?
        end

        def enabled?
          config[:filter_secrets].nil? ? DEFAULT_SETTING : config[:filter_secrets]
        end

        def apply
          sh.raw <<-SHELL
            if [[ -z "$TRAVIS_FILTERED" ]]; then
              export TRAVIS_FILTERED=1
              mkdir -p ~/.travis
              if [[ "$TRAVIS_OS_NAME" == osx ]]; then
                curl -sf -o #{redactor} #{Shellwords.escape(download_url('osx'))}
              else
                curl -sf -o #{redactor} #{Shellwords.escape(download_url('linux'))}
              fi
              chmod 0755 #{redactor}
              exec #{redactor} -r "/usr/bin/env TERM=xterm /bin/bash --login $HOME/build.sh" #{params}
            fi
          SHELL
        end

        private

          def host
            return 'build.travis-ci.com' if app_host.empty?
            app_host
          end

          def download_url(os_name)
            {
              'osx' => "https://#{host}/redactor_darwin_amd64".untaint,
              'linux' => "https://#{host}/redactor_linux_amd64".untaint,
            }.fetch(os_name)
          end

          def params
            secrets.map { |s| "-s #{Shellwords.escape(s)}".untaint }.join(' ')
          end

          def redactor
            '~/.travis/redactor'
          end

          def secrets
            @secrets ||= env.groups.flat_map(&:vars).select(&:secure?).map(&:value)
          end

          def env
            @env ||= Build::Env.new(data)
          end
      end
    end
  end
end
