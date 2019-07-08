require 'forwardable'

module Travis
  module Build
    class Env
      class Base < Struct.new(:env, :data)
        extend Forwardable

        def_delegators :data, :config, :job

        def to_vars(type, args)
          vars = Array(args).map { |arg| to_var(type, *arg) }.select(&:valid?)
          vars = vars.reject(&:secure?) unless data.secure_env?
          vars
        end

        def to_var(type, key, value, options = {})
          Var.new(key, value, options.merge(type: type))
        end

        def builtin?
          is_a?(Builtin)
        end

        def announce?
          !builtin? && vars.length > 0
        end

        def secure_vars?
          vars.any?(&:secure?)
        end
      end
    end
  end
end
