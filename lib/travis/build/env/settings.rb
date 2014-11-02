require 'travis/build/env/base'

module Travis
  module Build
    class Env
      class Settings < Base
        def source
          'repository settings'
        end

        def vars
          @vars ||= data.env_vars.map do |var|
            Var.new(var[:name], var[:value], !var[:public])
          end
        end
      end
    end
  end
end
