module Travis
  class Build
    class AssertionFailed < RuntimeError
      attr_reader :object, :method

      def initialize(object = nil, method = nil)
        @object = object
        @method = method
      end

      def to_s
        "#{object.inspect}: #{method}"
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
