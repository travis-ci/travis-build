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
            curl -sf -o ~/filter.rb #{Shellwords.escape(download_url)}
            exec > >(
              #{exports}
              ruby ~/filter.rb #{args}
            ) 2>&1
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

          def args
            secrets.size.times.map { |ix| "-e SECRET_#{ix}" }.join(" ")
          end

          def exports
            values = secrets.map(&:untaint)
            values = values.map { |value| Shellwords.escape(value) }
            values = values.map.with_index { |value, ix| "export SECRET_#{ix}=#{value}" }
            values.join(' ')
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
