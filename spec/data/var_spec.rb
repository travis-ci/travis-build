require 'spec_helper'

describe Travis::Build::Data::Var do
  def var(src)
    described_class.new(src)
  end

  it 'travis? returns true if the var name starts with TRAVIS_' do
    var('TRAVIS_FOO=foo').should be_travis
  end

  it 'secure? returns true if the var name starts with SECURE' do
    var('SECURE FOO=foo').should be_secure
  end

  describe 'echoize' do
    it 'returns false for internal vars' do
      var('TRAVIS_FOO=foo').echoize.should be_false
    end

    it 'obfuscates the value for secure vars' do
      var('SECURE FOO=foo').echoize.should == 'FOO=[secure]'
    end

    it 'returns the normal key=value string for normal vars' do
      var('FOO=foo').echoize.should == 'FOO=foo'
    end
  end
end
