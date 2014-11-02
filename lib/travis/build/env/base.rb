require 'forwardable'

module Travis
  module Build
    class Env
      class Base < Struct.new(:env, :data)
        extend Forwardable

        def_delegators :data, :config

        def to_vars(args)
          args.to_a.flat_map { |args| to_var(args) }
        end

        def to_var(args)
          Var.create(*args)
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
