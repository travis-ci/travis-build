require 'core_ext/string/indent'

module Travis
  module Shell
    module Ast
      class Cmd
        attr_reader :type, :data, :options

        def initialize(type, data = {}, options = {})
          @type = type
          @data = data
          @options = options.select { |key, value| value }
        end

        def to_sexp
          sexp = [type]
          sexp << data if data
          sexp << options if options.any?
          sexp
        end
      end

      class Cmds
        attr_reader :type, :nodes, :options

        def initialize(options = {}, &block)
          @nodes = []
          @options = options
          yield(self) if block_given?
        end

        def to_sexp
          [:cmds, nodes.map(&:to_sexp)]
        end
      end

      class Group < Cmds
        def initialize(type, options = {}, &block)
          @type = type
          super(options, &block)
        end

        def to_sexp
          [type, [:cmds, nodes.map(&:to_sexp)]]
        end
      end

      class Script < Cmds
        def to_sexp
          [:script, nodes.map(&:to_sexp)]
        end
      end

      class Fold < Cmds
        attr_reader :fold

        def initialize(fold, *args, &block)
          @fold = fold
          super(*args, &block)
        end

        def to_sexp
          [:fold, fold, super]
        end
      end

      class Trace < Cmds
        attr_reader :name

        def initialize(name, *args, &block)
          @name = name
          super(*args, &block)
        end

        def to_sexp
          [:trace, name, nodes.map(&:to_sexp)]
        end
      end

      class TraceRoot < Cmds
        def initialize(*args, &block)
          super(*args, &block)
        end

        def to_sexp
          [:trace_root, nodes.map(&:to_sexp)]
        end
      end

      class Conditional < Cmds
        attr_reader :condition

        def initialize(condition, *args, &block)
          @condition = condition
          super(*args, &block)
        end
      end

      class If < Conditional
        attr_reader :branches

        def initialize(condition, *args, &block)
          @branches = [Then.new]
          super(condition, *args, &block)
        end

        def nodes
          branches.first.nodes
        end

        def to_sexp
          sexp = [:if, condition, *branches.map(&:to_sexp)]
          sexp << { raw: true } if options[:raw]
          sexp
        end
      end

      class Then < Group
        def initialize(*args, &block)
          super(:then, *args, &block)
        end
      end

      class Elif < Conditional
        def to_sexp
          sexp = [:elif, condition, super]
          sexp << { raw: true } if options[:raw]
          sexp
        end
      end

      class Else < Group
        def initialize(*args, &block)
          super(:else, *args, &block)
        end
      end
    end
  end
end
