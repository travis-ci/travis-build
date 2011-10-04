module Travis
  module Build
    class AssertionFailed < RuntimeError
      attr_reader :object, :method

      def initialize(object, method)
        @object = object
        @method = method
      end
    end

    module Assertions
      def new(*args)
        super(*args).tap do |instance|
          (class << instance; self; end).send(:include, assertions)
        end
      end

      def assertions
        @assertions ||= Module.new
      end

      def assert(name)
        assertions.send(:define_method, name) do |*args|
          super(*args).tap do |result|
            raise AssertionFailed.new(self, name) unless result
          end
        end
      end
    end
  end
end
