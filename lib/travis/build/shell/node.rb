require 'shellwords'
require 'core_ext/string/indent'

module Travis
  module Build
    module Shell
      class Node
        attr_reader :code, :options, :level

        def initialize(*args)
          @options = args.last.is_a?(Hash) ? args.pop : {}
          @level = options.delete(:level) || 0
          @code = args.first
          yield(self) if block_given?
        end

        def name
          self.class.name.split('::').last.downcase
        end

        def to_s
          code ? code.indent(level) : code
        end

      end

      class Cmd < Node
      end

      class Group < Node
        Shell::Windows.instance_methods(false).each do |name|
          define_method(name) do |*args, &block|
            options = args.last if args.last.is_a?(Hash)
            args.last[:timeout] = data.timeouts[options[:timeout]] if options && options.key?(:timeout)
            sh.send(name, *args, &stacking(&block))
          end
        end

        attr_reader :nodes

        def initialize(*args, &block)
          @options = args.last.is_a?(Hash) ? args.pop : {}
          @builder = 
          @level = options.delete(:level) || 0
          @nodes = []
          args.map { |node| cmd(node) }
          yield(self) if block_given?
        end

        def to_s
          nodes.map(&:to_s).join("\n").indent(level)
        end
      end

      class Script < Group
        def to_s
          super + "\n"
        end
      end

      class Block < Group
        attr_reader :open, :close

        def to_s
          [open, super, close].compact.join("\n")
        end

        # TODO hrmmmm ... :/
        def script(*args)
          super(*merge_options(args, level: 1))
        end

        def cmd(code, *args)
          super(code, *merge_options(args, level: 1))
        end

        def raw(code, *args)
          super(code, *merge_options(args, level: 1))
        end
      end

      class Conditional < Block
        def initialize(condition, *args)
          args.unshift(args.last.delete(:then)) if args.last.is_a?(Hash) && args.last[:then]
          super(*args)
          @open = Node.new(if_cmd(name,condition), options)
        end
      end

      class If < Conditional
        def close
          Node.new(close_conditional(), options)
        end
      end

      class Elif < Conditional
      end

      class Else < Block
        def open
          @open = Node.new('else', options)
        end
      end
    end
  end
end
