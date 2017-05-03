require 'travis/build/appliances/base'
require 'travis/build/git'

module Travis
  module Build
    module Appliances
      class SetupFilter < Base
        def apply?
          secrets.any? and config[:filter_secrets]
        end

        def apply
          sh.raw <<-SHELL
            if [[ -z "$TRAVIS_FILTERED" ]]; then
              export TRAVIS_FILTERED=1
              #{exports}
              curl -sf -o ~/filter.rb #{Shellwords.escape(download_url)}
              exec ruby ~/filter.rb "$0" #{params}
            fi
          SHELL
        end

        private

          def download_url
            "https://#{app_host}/filter.rb"
          end

          def params
            secrets.size.times.map { |i| "-s $SECRET#{i}" }.join(" ")
          end

          def exports
            mapped = secrets.with_index.map do |value, index|
              "SECRET#{index}=#{Shellwords.escape(value)}"
            end
            mapped.join(" ")
          end

          def secrets
            @secrets ||= env.groups.flat_map { |g| g.vars }.select(&:secure?).map(&:value)
          end

          def env
            @env ||= Build::Env.new(data)
          end
      end
    end
  end
end
