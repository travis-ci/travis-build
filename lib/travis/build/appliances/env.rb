require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class Env < Base
        MSG = "Setting environment variables from %s"

        def apply
          env.groups.each { |group| export(group) }
          sh.newline if env.announce?
        end

        private

          def export(group)
            announce(group) if group.announce?
            group.vars.each do |var|
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
      end
    end
  end
end
