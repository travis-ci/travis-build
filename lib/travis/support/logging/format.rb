module Travis
  module Logging
    module Format
      class << self
        def format(severity, datetime, progname, msg)
          "#{severity[0, 1]} [#{datetime}] #{msg}\n"
        end

        def before(object, name, args)
          wrap(object, "about to #{name}#{self.arguments(args)}")
        end

        def after(object, name)
          wrap(object, "done: #{name}")
        end

        def wrap(object, message)
          "[#{object.log_header}] #{message}"
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
