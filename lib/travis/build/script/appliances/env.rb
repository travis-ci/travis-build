require 'travis/build/script/appliances/base'

module Travis
  module Build
    class Script
      module Appliances
        class Env < Base
          def apply
            sh.export 'TRAVIS', 'true', echo: false
            sh.export 'CI', 'true', echo: false
            sh.export 'CONTINUOUS_INTEGRATION', 'true', echo: false
            sh.export 'HAS_JOSH_K_SEAL_OF_APPROVAL', 'true', echo: false

            sh.newline if data.env_vars_groups.any?(&:announce?)

            data.env_vars_groups.each do |group|
              sh.echo "Setting environment variables from #{group.source}", ansi: :yellow if group.announce?
              group.vars.each { |var| sh.export(var.key, var.value, echo: var.echo?, secure: var.secure?) }
            end

            sh.newline if data.env_vars_groups.any?(&:announce?)
          end
        end
      end
    end
  end
end
