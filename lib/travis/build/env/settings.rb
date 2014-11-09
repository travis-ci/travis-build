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
            data.env_vars.map do |var|
              [var[:name], var[:value], secure: !var[:public]]
            end
          end
      end
    end
  end
end
