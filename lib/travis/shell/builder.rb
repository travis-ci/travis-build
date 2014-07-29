module Travis
  module Shell
    class Builder
      attr_reader :stack
      attr_accessor :options

      def initialize
        @stack = [Shell::Ast::Script.new]
        @options = {}
      end

      def sh # rename to node?
        stack.last
      end

      def to_sexp
        sh.to_sexp
      end

      def script(*args, &block)
        block = with_node(&block) if block
        sh.nodes << Shell::Ast::Script.new(*merge_options(args), &block)
      end

      def node(type, data = nil, *args)
        args = merge_options(args)
        if fold = args.last.delete(:fold)
          fold(fold) { node(type, data, *args) }
        else
          node = Shell::Ast::Cmd.new(type, data, *args)
          sh.nodes.insert(args.last.delete(:pos) || -1, node)
        end
      end

      def raw(code)
        node :raw, code
      end

      def cmd(data, *args)
        node :cmd, data, *args
      end

      def export(type, value, options = {})
        node :export, [type, value], { assert: false, echo: true, timing: false }.merge(options)
      end
      alias set export

      def echo(string = '', options = {})
        string.split("\n").each do |line|
          if line.empty?
            newline
          else
            node :echo, line, { assert: false, echo: false, timing: false }.merge(options)
          end
        end
      end

      def newline
        node :newline, nil, timing: false
      end

      def terminate(message)
        echo message
        cmd 'false'
      end

      def cd(path, options = {})
        node :cd, path, { assert: false, echo: true, timing: false }.merge(options)
      end

      def file(path, content, options = {})
        node :file, [content, path], { assert: false, echo: false, timing: false }.merge(options)
      end

      def chmod(mode, file, options = {})
        node :chmod, [mode, file], { timing: false }.merge(options)
      end

      def mkdir(path, options = {})
        node :mkdir, path, { assert: !options[:recursive], echo: true, timing: false }.merge(options)
      end

      def cp(source, target, options = {})
        node :cp, [source, target], { assert: true, echo: true, timing: false }.merge(options)
      end

      def mv(source, target, options = {})
        node :mv, [source, target], { assert: true, echo: true, timing: false }.merge(options)
      end

      def rm(path, options = {})
        node :rm, path, { assert: !options[:force], timing: false }.merge(options)
      end

      def fold(name, &block)
        args = merge_options(name)
        block = with_node(&block) if block
        sh.nodes << Shell::Ast::Fold.new(*args, &block)
      end

      def if(*args, &block)
        block = with_node(&block) if block
        args = merge_options(args)
        then_ = args.last.delete(:then)
        else_ = args.last.delete(:else)

        node = Shell::Ast::If.new(*args, &block)
        node.last.cmd(then_, args.last) if then_
        node.last.else(else_, args.last) if else_
        sh.nodes << node
      end

      def then(&block)
        block = with_node(&block) if block
        yield self
      end

      def elif(*args, &block)
        block = with_node(&block) if block
        args = merge_options(args)
        sh.nodes.last.branches << Shell::Ast::Elif.new(*args, &block)
      end

      def else(*args, &block)
        block = with_node(&block) if block
        args = merge_options(args)
        sh.nodes.last.branches << Shell::Ast::Else.new(*args, &block)
        # rgt.cmd(*args) unless args.first.is_a?(Hash)
      end

      private

        def merge_options(args)
          args = Array(args)
          options = args.last.is_a?(Hash) ? args.pop : {}
          options = self.options.merge(options)
          # options = { timing: true }.merge(options)
          args << options
        end

        def with_node
          ->(node) {
            stack.push(node)
            result = yield if block_given?
            stack.pop
            result
          }
        end
    end
  end
end
