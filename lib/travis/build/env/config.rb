require 'travis/build/env/base'

module Travis
  module Build
    class Env
      class Config < Base
        def source
          '.travis.yml'
        end

        def vars
          @vars ||= to_vars(:config, env_vars)
        end

        private

          def env_vars
            vars = Array(config[:global_env]) + Array(config[:env])
            vars = vars.compact.reject(&:empty?)
            vars.flat_map { |var| Var.parse(var) }
          end
      end
    end
  end
end
