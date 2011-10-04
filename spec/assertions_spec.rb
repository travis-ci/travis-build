require 'spec_helper'

describe Assertions do
  class AssertionsTest
    extend Assertions

    def initialize(return_value)
      @return_value = return_value
    end

    def asserted_method
      @return_value
    end
    assert :asserted_method
  end

  subject do
    lambda { AssertionsTest.new(@return_value).asserted_method }
  end

  describe 'an asserted method' do
    it 'does not raise an exception when the returned values is true' do
      @return_value = true
      should_not raise_error(AssertionFailed)
    end

    it 'raises an exception when the returned values is false' do
      @return_value = false
      should raise_error(AssertionFailed)
    end
  end
end
