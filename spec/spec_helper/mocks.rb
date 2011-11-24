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
    def name
      'vm-name'
    end

    def full_name
      'the-full:vm-name'
    end

    def sandboxed
      yield
    end
  end

  class Shell
    def initialize
      # stubs(:connect => nil, :close => nil, :execute => true, :evaluate => '')
    end

    def echo(*)
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
