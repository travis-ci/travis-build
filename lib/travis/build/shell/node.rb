require 'shellwords'
require 'core_ext/string/indent'

module Travis
  module Build
    module Shell
      class Node
        include Dsl

        attr_reader :code, :options, :level

        def initialize(*args)
          @options = args.last.is_a?(Hash) ? args.pop : {}
          @level = options.delete(:level) || 0
          @code = args.first
          with_sh(self, &block) if block_given?
        end

        def name
          self.class.name.split('::').last.downcase
        end

        def to_s
          code ? code.indent(level) : code
        end

        def escape(code)
          Shellwords.escape(code)
        end
      end

      class Cmd < Node
        def code
          if opts.any?
            ['travis_cmd', escape(super), *opts].join(' ')
          else
            super
          end
        end

        def opts
          opts ||= []
          opts << '--assert' if options[:assert]
          opts << '--echo'   if options[:echo]
          opts << '--retry'  if options[:retry]
          opts << '--timing' if options[:timing]
          opts << "--display #{escape(options[:echo])}" if options[:echo].is_a?(String)
          opts
        end
      end

      class Group < Node
        include Dsl

        attr_reader :nodes

        def initialize(*args, &block)
          @options = args.last.is_a?(Hash) ? args.pop : {}
          @level = options.delete(:level) || 0
          @nodes = []
          args.map { |node| cmd(node, options) }
          with_sh(self, &block) if block_given?
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
        def initialize(condition, *args, &block)
          args.unshift(args.last.delete(:then)) if args.last.is_a?(Hash) && args.last[:then]
          unless args.last.delete(:raw_condition)
            condition = "[[ #{condition} ]]"
          end
          super(*args, &block)
          @open = Node.new("#{name} #{condition}; then", options)
        end
      end

      class If < Conditional
        def close
          Node.new('fi', options)
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
