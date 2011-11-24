require 'spec_helper'
require 'travis/support'

describe Travis::Assertions do
  class A
    extend Travis::Assertions

    def initialize(result)
      @result = result
    end

    def the_method
      @result
    end
    assert :the_method
  end

  subject { lambda { A.new(@return_value).the_method } }

  describe 'an asserted method' do
    it 'does not raise an exception when the returned values is true' do
      @return_value = true
      should_not raise_error(Travis::AssertionFailed)
    end

    it 'raises an exception when the returned values is false' do
      @return_value = false
      should raise_error(Travis::AssertionFailed)
    end
  end
end
