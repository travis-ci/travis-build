require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class Env < Base
        MSG = "Setting environment variables from %s"

        def_delegators :script, :debug_enabled?, :debug_build_via_api?

        def apply
          if data.secure_env_removed?
            sh.echo ""
            sh.echo "Encrypted environment variables have been removed for security reasons.", ansi: :yellow
            sh.echo "See https://docs.travis-ci.com/user/pull-requests/#Pull-Requests-and-Security-Restrictions", ansi: :yellow
          end

          env.groups.each { |group| export(group) }
          sh.newline if env.announce?
        end

        private

          def export(group)
            announce(group) if group.announce?
            vars = group.vars

            if (debug_enabled? || debug_build_via_api?) && hide_secrets?
              if vars.reject!(&:secure?)
                sh.echo "Removed secrets while running in debug mode"
              end
            end

            vars.each do |var|
              sh.export(var.key, var.value, echo: var.echo?, secure: var.secure?)
            end
          end

          def announce(group)
            sh.newline
            sh.echo MSG % group.source, ansi: :yellow
          end

          def env
            @env ||= Build::Env.new(data)
          end

          def hide_secrets?
            Travis::Build.config.hide_secrets_in_debug == '1'
          end
      end
    end
  end
end
