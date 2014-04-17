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
      expect(parse('SECURE FOO=foo BAR=bar')).to eq([["SECURE FOO", "foo"], ["SECURE BAR", "bar"]])
    end

    it 'parses FOO=foo BAR=bar' do
      expect(parse('FOO=foo BAR=bar')).to eq([['FOO', 'foo'], ['BAR', 'bar']])
    end

    it 'parses FOO="" BAR=bar' do
      expect(parse('FOO="" BAR=bar')).to eq([['FOO', '""'], ['BAR', 'bar']])
    end

    it 'parses FOO="foo" BAR=bar' do
      expect(parse('FOO="foo" BAR=bar')).to eq([['FOO', '"foo"'], ['BAR', 'bar']])
    end

    it 'parses FOO="foo" BAR="bar"' do
      expect(parse('FOO="foo" BAR="bar"')).to eq([['FOO', '"foo"'], ['BAR', '"bar"']])
    end

    it "parses FOO='' BAR=bar" do
      expect(parse("FOO='' BAR=bar")).to eq([['FOO', "''"], ['BAR', 'bar']])
    end

    it "parses FOO='foo' BAR=bar" do
      expect(parse("FOO='foo' BAR=bar")).to eq([['FOO', "'foo'"], ['BAR', 'bar']])
    end

    it "parses FOO='foo' BAR='bar'" do
      expect(parse("FOO='foo' BAR='bar'")).to eq([['FOO', "'foo'"], ['BAR', "'bar'"]])
    end

    it "parses FOO='foo' BAR=\"bar\"" do
      expect(parse("FOO='foo' BAR=\"bar\"")).to eq([['FOO', "'foo'"], ['BAR', '"bar"']])
    end

    it 'parses FOO="foo foo" BAR=bar' do
      expect(parse('FOO="foo foo" BAR=bar')).to eq([['FOO', '"foo foo"'], ['BAR', 'bar']])
    end

    it 'parses FOO="foo foo" BAR="bar bar"' do
      expect(parse('FOO="foo foo" BAR="bar bar"')).to eq([['FOO', '"foo foo"'], ['BAR', '"bar bar"']])
    end
  end

  it 'travis? returns true if the var name starts with TRAVIS_' do
    expect(var(:TRAVIS_FOO, 'foo')).to be_travis
  end

  it 'secure? returns true if the var name starts with SECURE' do
    expect(var('SECURE FOO', 'foo')).to be_secure
  end

  describe 'to_s' do
    it 'returns false for internal vars' do
      expect(var(:TRAVIS_FOO, 'foo').to_s).to be_falsey
    end

    it 'obfuscates the value for secure vars' do
      expect(var('SECURE FOO', 'foo').to_s).to eq('export FOO=[secure]')
    end

    it 'returns the normal key=value string for normal vars' do
      expect(var('FOO', 'foo').to_s).to eq('export FOO=foo')
    end
  end
end
