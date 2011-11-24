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

      def log_before(*args)
        logger.info(Format.before(*args))
      end

      def log_after(*args)
        logger.debug(Format.after(*args))
      end

      def log_exception(exception)
        logger.error(Format.exception(exception))
      end
    end

    delegate :logger, :to => Travis
    delegate :fatal, :error, :warn, :info, :debug, :to => :logger
    delegate :log_before, :log_after, :log_exception, :to => Logging

    def log_header
      self.class.log_header ? instance_eval(&self.class.log_header) : self.class.name.split('::').last.downcase
    end

    module ClassMethods
      def log_header(header = nil, &block)
        block = lambda { header } if !block && header
        block ? @log_header = block : @log_header
      end

      def log(name, options = {})
        define_method(:"#{name}_with_log") do |*args, &block|
          arguments = options[:params].is_a?(FalseClass) ? [] : [args]
          log_before(self, name, arguments) unless options[:only] == :after
          send(:"#{name}_without_log", *args, &block).tap do |result|
            log_after(self, name) unless options[:only] == :before
          end
        end
        alias_method_chain name, 'log'
      end
    end
  end
end
