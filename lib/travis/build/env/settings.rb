require 'travis/build/env/base'

module Travis
  module Build
    class Env
      class Settings < Base
        def source
          'repository settings'
        end

        def vars
          @vars ||= to_vars(:settings, env_vars)
        end

        private

          def env_vars
            branch_specific, default = data.env_vars.partition { |v| v[:branch] == job[:branch]}

            (default + branch_specific).map do |var|
              if var[:branch].to_s.empty? || var[:branch] == job[:branch]
                [var[:name], var[:value], secure: !var[:public]]
              else
                nil
              end
            end.compact
          end
      end
    end
  end
end
