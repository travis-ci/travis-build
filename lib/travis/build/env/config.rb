require 'travis/build/env/base'

module Travis
  module Build
    class Env
      class Config < Base
        def source
          '.travis.yml'
        end

        def vars
          @vars ||= begin
            vars = to_vars(env_vars)
            vars.reject!(&:secure?) unless data.secure_env?
            vars
          end
        end

        private

          def env_vars
            config.values_at(:global_env, :env).flatten.compact.reject(&:empty?)
          end
      end
    end
  end
end
