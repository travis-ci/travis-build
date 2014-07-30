module Travis
  module Build
    module Shell
      module Dsl
        def script(*args, &block)
          nodes << Script.new(*merge_options(args), &block)
          nodes.last
        end

        def cmd(code, *args)
          options = args.last.is_a?(Hash) ? args.last : {}
          node = Cmd.new(code, *merge_options(args))
          options[:fold] ? fold(options[:fold]) { raw(node) } : raw(node)
        end

        def raw(code, *args)
          args = merge_options(args)
          pos = args.last.delete(:pos) || -1
          node = code.is_a?(Node) ? code : Node.new(code, *args)
          nodes.insert(pos, node)
        end

        def export(name, value, options = {})
          cmd "export #{name}=#{value}", { assert: false, timing: false }.merge(options)
        end
        alias set export

        def echo(string, options = {})
          string = ansi(string, options) if options[:ansi]
          cmd "echo -e #{escape(string)}", { assert: false, echo: false, timing: false }.merge(options)
        end

        def newline
          raw 'echo'
        end

        def cd(path)
          cmd "cd #{path}", echo: true, timing: false
        end

        def file(path, content)
          raw "echo #{escape(content)} > #{path}"
        end

        def if(*args, &block)
          args = merge_options(args)
          els_ = args.last.delete(:else)
          nodes << If.new(*args, &block)
          self.else(els_, args.last) if els_
          nodes.last
        end

        def elif(*args, &block)
          raise InvalidParent.new(Elif, If, nodes.last.class) unless nodes.last.is_a?(If)
          args = merge_options(args)
          els_ = args.last.delete(:else)
          nodes.last.raw Elif.new(*args, &block)
          self.else(els_, args.last) if els_
          nodes.last
        end

        def else(*args, &block)
          raise InvalidParent.new(Else, If, nodes.last.class) unless nodes.last.is_a?(If)
          nodes.last.raw Else.new(*merge_options(args), &block)
          nodes.last
        end

        def fold(name, &block)
          raw "travis_fold start #{name}"
          result = yield(self)
          raw "travis_fold end #{name}"
          result
        end

        private

          def merge_options(args, options = {})
            options = (args.last.is_a?(Hash) ? args.pop : {}).merge(options)
            args << self.options.merge(options)
          end

          ANSI = {
            green:  '\033[32;1m',
            red:    '\033[31;1m',
            yellow: '\033[33;1m',
            reset:  '\033[0m'
          }

          def ansi(string, options)
            keys = Array(options[:ansi])
            prefix = keys.map { |key| ANSI[key] }
            lines = string.split("\n").map do |line|
              line.strip.empty? ? line : [prefix, line, ANSI[:reset]].flatten.join
            end
            lines.join("\n")
          end
      end
    end
  end
end
