require 'hashr'

module Mocks
  class Observer
    def events
      @events ||= []
    end

    def notify(event)
      events << event
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

      attr_reader :session, :order

      def initialize(session)
        @session = session
        @order = sequence('ssh commands')
      end

      def method_missing(method, *args, &block)
        session.expects(method).in_sequence(order).with(*args)
      end
    end

    attr_reader :config

    def initialize(config)
      @config = Hashr.new(config)
      # stubs(:connect => nil, :close => nil, :execute => true, :evaluate => '')
    end

    def expect(*args)
      yield Expector.new(self)
    end

    def on_output(&block)
      $on_output = block
    end
  end
end

Mocha::Expectation.class_eval do
  class OutputSideEffect
    attr_reader :mock, :output

    def initialize(mock, output)
      @mock = mock
      @output = output
    end

    def perform
      $on_output.call(output) # OMFG HAX0R
    end

    def mocha_inspect
      "outputs #{output.inspect}"
    end
  end

  def outputs(output)
    add_side_effect(OutputSideEffect.new(@mock, output))
    self
  end
end
