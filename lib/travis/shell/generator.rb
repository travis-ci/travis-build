module Travis
  module Shell
    class Generator
      TaintedOutput = Class.new(StandardError)

      attr_reader :nodes, :level

      def initialize(nodes)
        @nodes = nodes
        @level = 0
      end

      def generate
        lines = Array(handle(nodes)).flatten.compact
        script = lines.join("\n").strip
        raise TaintedOutput if script.tainted?
        script = unindent(script)
        script = normalize_newlines(script)
        script
      end

      private

        def handle(node)
          node = node.dup
          type = node.shift
          send(:"handle_#{type}", *node)
        end

        def handle_raw(code, *)
          code
        end

        def handle_script(nodes)
          nodes.map { |node| handle(node) }
        end
        alias handle_cmds handle_script

        def handle_group(name, cmds = nil)
          cmds ? handle(cmds) : nil
        end

        def indent(lines = nil)
          @level += 1
          lines = Array(lines || yield).flatten.compact
          lines = lines.map { |line| line.split("\n").map { |line| "  #{line}" }.join("\n") }
          @level -= 1
          lines
        end

        def unindent(string)
          string.gsub /^#{string[/\A\s*/]}/, ''
        end

        def normalize_newlines(string)
          string.gsub("\n\n\n", "\n\n")
        end

        def with_margin
          code = []
          code << '' if level == 0
          code << yield
          code << '' if level == 0
          code
        end
    end
  end
end
