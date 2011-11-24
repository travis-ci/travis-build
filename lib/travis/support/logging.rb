require 'active_support/core_ext/module/delegation'
require 'active_support/core_ext/module/aliasing'
require 'logger'

module Travis
  module Logging
    autoload :Format, 'travis/support/logging/format'

    class << self
      def included(base)
        base.extend(ClassMethods)
      end

      delegate :logger, :to => Travis

      def configure(logger)
        logger.tap do
          logger.formatter = proc { |*args| Format.format(*args) }
          logger.level = Logger.const_get(:debug.to_s.upcase) # TODO set from Travis::Worker.config or something
        end
      end

      def before(type, *args)
        logger.send(type || :info, Format.before(*args))
      end

      def after(type, *args)
        logger.send(type || :debug, Format.after(*args))
      end
    end

    delegate :logger, :to => Travis

    [:fatal, :error, :warn, :info, :debug].each do |level|
      define_method(level) do |*args|
        message, options = *args
        message.chomp.split("\n").each do |line|
          logger.send(level, Logging::Format.wrap(self, line, options || {}))
        end
      end
    end

    def log_exception(exception)
      logger.error(Logging::Format.wrap(self, "#{exception.class.name}: #{exception.message}"))
      exception.backtrace.each do |line|
        logger.error(Logging::Format.wrap(self, line))
      end if exception.backtrace
    end

    def log_header
      self.class.log_header ? instance_eval(&self.class.log_header) : self.class.name.split('::').last.downcase
    end

    module ClassMethods
      def log_header(&block)
        block ? @log_header = block : @log_header
      end

      def log(name, options = {})
        define_method(:"#{name}_with_log") do |*args, &block|
          arguments = options[:params].is_a?(FalseClass) ? [] : args
          Logging.before(options[:as], self, name, arguments) unless options[:only] == :after
          send(:"#{name}_without_log", *args, &block).tap do |result|
            Logging.after(options[:as], self, name) unless options[:only] == :before
          end
        end
        alias_method_chain name, 'log'
      end
    end
  end
end
