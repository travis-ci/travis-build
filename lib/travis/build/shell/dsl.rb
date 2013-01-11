require 'shellwords'

module Travis
  module Build
    module Shell
      module Dsl
        def script(*args, &block)
          nodes << Script.new(*merge_options(args), &block)
          nodes.last
        end

        def cmd(code, *args)
          raw Cmd.new(code, *merge_options(args))
        end

        def raw(code, *args)
          nodes << (code.is_a?(Node) ? code : Node.new(code, *merge_options(args)))
        end

        def set(var, value, options = {})
          cmd "#{var}=#{value}", options.merge(log: false)
        end

        def echo(string, options = {})
          cmd "echo #{Shellwords.escape(string)}", echo: false, log: true
        end

        def cd(path)
          cmd "cd #{path}", echo: true, log: false
        end

        def if(*args, &block)
          args = merge_options(args)
          els_ = args.last.delete(:else)
          nodes << If.new(*args, &block)
          self.else(els_, args.last) if els_
          nodes.last
        end

        def elif(*args, &block)
          raise InvalidParent(Elif, If) unless nodes.last.is_a?(If)
          args = merge_options(args)
          els_ = args.last.delete(:else)
          nodes.last.raw Elif.new(*args, &block)
          self.else(els_, args.last) if els_
          nodes.last
        end

        def else(*args, &block)
          raise InvalidParent(Else, If) unless nodes.last.is_a?(If)
          nodes.last.raw Else.new(*merge_options(args), &block)
          nodes.last
        end

        private

          def merge_options(args, options = {})
            options = (args.last.is_a?(Hash) ? args.pop : {}).merge(options)
            args << self.options.merge(options)
          end
      end
    end
  end
end
