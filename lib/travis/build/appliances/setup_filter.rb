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
              #{exports}
              curl -sf -o ~/filter.rb #{Shellwords.escape(download_url)}
              exec ruby ~/filter.rb "/usr/bin/env TERM=xterm /bin/bash --login $HOME/build.sh" #{params}
            fi
          SHELL
        end

        private

          def host
            return 'build.travis-ci.com' if app_host.empty?
            app_host
          end

          def download_url
            "https://#{host}/filter.rb".untaint
          end

          def params
            secrets.size.times.map { |i| "-s \"$SECRET#{i}\"" }.join(" ")
          end

          def exports
            mapped = secrets.each_with_index.map do |value, index|
              "SECRET#{index}=#{Shellwords.escape(value).untaint}"
            end
            mapped.join(" ")
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
