module Travis
  module Logging
    module Format
      class << self
        def format(severity, time, progname, msg)
          "#{severity[0, 1]} [#{format_time(time)}] #{msg}\n"
        end

        def format_time(time)
          time.strftime("%Y-%m-%d %H:%M:%S.") << time.usec.to_s[0, 3]
        end

        def before(object, name, args)
          wrap(object, "about to #{name}#{self.arguments(args)}")
        end

        def after(object, name)
          wrap(object, "done: #{name}")
        end

        def wrap(object, message, options = {})
          header = options[:header] || object.log_header
          "[#{header}] #{message.chomp}"
        end

        def exception(object, exception)
          wrap(object, ([message] + backtrace).join("\n"))
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
