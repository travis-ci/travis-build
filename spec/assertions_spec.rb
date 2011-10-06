require 'spec_helper'

describe Assertions do
  let :asserting_class do
    Class.new do |c|
      c.extend(Assertions)
      c.send(:define_method, :initialize) { |return_value| @return_value = return_value }
      c.send(:define_method, :the_method) { @return_value }
      c.assert(:the_method)
    end
  end

  subject do
    lambda { asserting_class.new(@return_value).the_method }
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
