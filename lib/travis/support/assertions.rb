require 'active_support/core_ext/module/aliasing'

module Travis
  class AssertionFailed < RuntimeError
    attr_reader :object, :method

    def initialize(object = nil, method = nil)
      @object = object
      @method = method
    end

    def to_s
      "#{object.inspect}##{method} did not return true."
    end
  end

  module Assertions
    def assert(name)
      define_method(:"#{name}_with_assert") do |*args, &block|
        send(:"#{name}_without_assert", *args, &block).tap do |result|
          raise Travis::AssertionFailed.new(self, name) unless result
        end
      end
      alias_method_chain name, 'assert'
    end
  end
end

class Module
  def define_assertion(name)
  end
end
