module Mocks
  class Observer
    def events
      @events ||= []
    end

    def notify(*args)
      events << args
    end
  end

  class Vm
    def sandboxed
      yield
    end
  end

  class SshSession
    class Expector
      include Mocha::API

      attr_reader :object, :order

      def initialize(object)
        @object = object
        @order = sequence('ssh commands')
      end

      def method_missing(method, *args, &block)
        object.expects(method).in_sequence(order).with(*args)
      end
    end

    attr_reader :config

    def initialize(config)
      @config = Hashr.new(config)
      stubs(:connect => nil, :close => nil)
    end

    def expect(*args)
      yield Expector.new(self)
    end

    def on_output(&block)
      @on_output = block
    end
  end
end
