module Travis
  module Shell
    class Generator
      TaintedOutput = Class.new(StandardError)

      attr_reader :nodes, :level, :trace
      MAX_SPAN_ID = 0xffffffffffffffff

      def initialize(nodes)
        @nodes = nodes
        @level = 0
        @trace = [
          # root span id
          rand(1..MAX_SPAN_ID).to_s(16).rjust(16, "0")
        ]
      end

      def generate(ignore_taint = false)
        lines = Array(handle(nodes)).flatten
        script = lines.join("\n").strip
        raise TaintedOutput if !ignore_taint && script.tainted?
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

        def handle_cmds(nodes)
          indent { handle_script(nodes) }
        end

        def indent(lines = nil)
          @level += 1
          lines = Array(lines || yield).flatten.map { |line| line.split("\n").map { |line| "  #{line}" }.join("\n") }
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

        def with_span(span_id)
          @trace << span_id
          lines = yield
          @trace.pop
          lines
        end

        def parent_span_id
          @trace.last
        end

        def root_span_id
          @trace.first
        end
    end
  end
end
