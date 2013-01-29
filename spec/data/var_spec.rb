require 'spec_helper'

describe Travis::Build::Data::Var do
  def parse(line)
    described_class.parse(line)
  end

  def var(key, value)
    described_class.new(key, value)
  end

  describe 'parse' do
    it 'parses SECURE FOO=foo BAR=bar' do
      parse('SECURE FOO=foo BAR=bar').should == [["SECURE FOO", "foo"], ["SECURE BAR", "bar"]]
    end

    it 'parses FOO=foo BAR=bar' do
      parse('FOO=foo BAR=bar').should == [['FOO', 'foo'], ['BAR', 'bar']]
    end

    it 'parses FOO="" BAR=bar' do
      parse('FOO="" BAR=bar').should == [['FOO', '""'], ['BAR', 'bar']]
    end

    it 'parses FOO="foo" BAR=bar' do
      parse('FOO="foo" BAR=bar').should == [['FOO', '"foo"'], ['BAR', 'bar']]
    end

    it 'parses FOO="foo" BAR="bar"' do
      parse('FOO="foo" BAR="bar"').should == [['FOO', '"foo"'], ['BAR', '"bar"']]
    end

    it "parses FOO='' BAR=bar" do
      parse("FOO='' BAR=bar").should == [['FOO', "''"], ['BAR', 'bar']]
    end

    it "parses FOO='foo' BAR=bar" do
      parse("FOO='foo' BAR=bar").should == [['FOO', "'foo'"], ['BAR', 'bar']]
    end

    it "parses FOO='foo' BAR='bar'" do
      parse("FOO='foo' BAR='bar'").should == [['FOO', "'foo'"], ['BAR', "'bar'"]]
    end

    it "parses FOO='foo' BAR=\"bar\"" do
      parse("FOO='foo' BAR=\"bar\"").should == [['FOO', "'foo'"], ['BAR', '"bar"']]
    end

    it 'parses FOO="foo foo" BAR=bar' do
      parse('FOO="foo foo" BAR=bar').should == [['FOO', '"foo foo"'], ['BAR', 'bar']]
    end

    it 'parses FOO="foo foo" BAR="bar bar"' do
      parse('FOO="foo foo" BAR="bar bar"').should == [['FOO', '"foo foo"'], ['BAR', '"bar bar"']]
    end
  end

  it 'travis? returns true if the var name starts with TRAVIS_' do
    var(:TRAVIS_FOO, 'foo').should be_travis
  end

  it 'secure? returns true if the var name starts with SECURE' do
    var('SECURE FOO', 'foo').should be_secure
  end

  describe 'to_s' do
    it 'returns false for internal vars' do
      var(:TRAVIS_FOO, 'foo').to_s.should be_false
    end

    it 'obfuscates the value for secure vars' do
      var('SECURE FOO', 'foo').to_s.should == 'export FOO=[secure]'
    end

    it 'returns the normal key=value string for normal vars' do
      var('FOO', 'foo').to_s.should == 'export FOO=foo'
    end
  end
end
