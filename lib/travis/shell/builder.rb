module Travis
  module Shell
    class Builder
      class InvalidCmd < StandardError
        def initialize(type, cmd)
          super("#{type.inspect} must be followed by a non-empty String, but #{cmd.inspect} was given")
        end
      end

      attr_reader :stack
      attr_accessor :options

      def initialize(trace_enabled = false)
        @stack = [Shell::Ast::Script.new]
        @options = {}
        @trace_enabled = trace_enabled
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
          pos = args.last.delete(:pos)
          node = Shell::Ast::Cmd.new(type, data, *args)
          sh.nodes.insert(pos || -1, node)
        end
      end

      def raw(code, options = {})
        node :raw, code, echo: false, timing: false, pos: options[:pos]
      end

      def cmd(data, *args)
        # validate_non_empty_string!(:cmd, data)
        trace(data) {
          node :cmd, data, *args
        }
      end

      def set(name, value, options = {})
        node :set, [name, value], { assert: false, echo: true, timing: false }.merge(options)
      end

      def export(name, value, options = {})
        node :export, [name, value], { assert: false, echo: true, timing: false }.merge(options)
      end

      def echo(msg = '', options = {})
        if msg.empty?
          newline
        else
          node :echo, msg, { assert: false, echo: false, timing: false }.merge(options)
        end
      end

      def deprecate(msg)
        lines = msg.split("\n")
        lines.each.with_index do |line|
          node :echo, line, ansi: :red
        end
        newline(pos: lines.size)
      end

      def newline(options = {})
        node :newline, nil, { timing: false }.merge(options)
      end

      def terminate(result = 2, message = nil, options = {})
        echo message, options if message
        raw "travis_terminate #{result}"
      end

      def failure(message = nil)
        export 'TRAVIS_CMD', 'no_script', echo: false
        echo message if message
        raw 'travis_run_after_failure'
        raw 'set -e'
        raw 'false'
      end

      def cd(path, options = {})
        validate_non_empty_string!(:cd, path) unless path == :back
        node :cd, path, { assert: false, echo: true, timing: false }.merge(options)
      end

      def file(path, content, options = {})
        node :file, [path, content], { assert: false, echo: false, timing: false }.merge(options)
      end

      def chmod(mode, file, options = {})
        node :chmod, [mode, file], { timing: false }.merge(options)
      end

      def chown(owner, file, options = {})
        node :chown, [owner, file], { timing: false }.merge(options)
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

      def fold(name, options = {}, &block)
        args = merge_options(name)
        block = with_node(&block) if block
        node = Shell::Ast::Fold.new(*args, &block)
        sh.nodes.insert(options[:pos] || -1, node)
      end

      def trace(*args, &block)
        unless @trace_enabled
          return yield
        end
        args = merge_options(args)
        block = with_node(&block) if block
        node = Shell::Ast::Trace.new(*args, &block)
        sh.nodes << node
      end

      def trace_root(*args, &block)
        unless @trace_enabled
          return yield
        end
        args = merge_options(args)
        block = with_node(&block) if block
        node = Shell::Ast::TraceRoot.new(*args, &block)
        sh.nodes << node
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
      end

      def with_options(options)
        options, @options = @options, options
        yield
        @options = options
      end

      def with_errexit_off
        save_and_switch_off_errexit
        yield
        restore_errexit
      end

      def save_and_switch_off_errexit
        self.if "$- = *e*" do
          raw 'ERREXIT_SET=true'
        end
        raw 'set +e'
      end

      def restore_errexit
        self.if "-n $ERREXIT_SET" do
          raw 'set -e'
        end
      end

      private

        def merge_options(args)
          args = Array(args)
          options = args.last.is_a?(Hash) ? args.pop : {}
          options = self.options.merge(options)
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

        def validate_non_empty_string!(cmd, str)
          raise InvalidCmd.new(cmd, str) unless str.is_a?(String) && !str.empty?
        end
    end
  end
end
