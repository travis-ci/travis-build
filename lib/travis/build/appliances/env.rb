require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class Env < Base  
        MSG = "Setting environment variables from %s"

        def apply
          if data.secure_env_removed?
            sh.newline
            sh.echo "Encrypted environment variables have been removed for security reasons.", ansi: :yellow
            sh.echo "See https://docs.travis-ci.com/user/pull-requests/#pull-requests-and-security-restrictions", ansi: :yellow
          end

          env.groups.each { |group| export(group) }
          sh.newline if env.announce?
        end

        def apply?
          true
        end

        private

          def export(group)
            announce(group) if group.announce?
            group.vars.each do |var|
              if var.branch.to_s.empty? || var.branch == data.job[:branch].to_s
                sh.export(var.key, var.value + '_'+ var.branch + '_' + data.job[:branch].to_s, echo: var.echo?, secure: var.secure?)
              end
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
