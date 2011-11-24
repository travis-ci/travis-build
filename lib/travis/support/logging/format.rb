module Travis
  module Logging
    module Format
      class << self
        def format(severity, datetime, progname, msg)
          "#{severity[0]} [#{datetime}] #{msg}\n"
        end

        def before(object, name, args)
          "#{header(object)} about to #{name}#{self.arguments(args)}"
        end

        def after(object, name)
          "#{header(object)} done: #{name}"
        end

        def header(object)
          "[#{object.log_header}]"
        end

        def exception(exception)
          (["#{exception.class.name}: #{exception.message}"] + (exception.backtrace || [])).join("\n")
        end

        def arguments(args)
          args.empty? ? '' : "(#{args.map { |arg| self.argument(arg).inspect }.join(', ')})"
        end

        def argument(arg)
          if arg.is_a?(Hash) && arg.key?(:log) && arg[:log].size > 80
            arg = arg.dup
            arg[:log] = "#{arg[:log][0..80]} ..."
          end
          arg
        end
      end
    end
  end
end
