require 'spec_helper'

describe Travis::Build::Data::Var do
  def parse(line)
    described_class.parse(line)
  end

  def var(key, value, secure = nil)
    described_class.new(key, value, secure)
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

  describe 'secure?' do
    it 'returns true if the var name starts with SECURE' do
      expect(var('SECURE FOO', 'foo')).to be_secure
    end

    it 'returns true if var is created with secure argument' do
      expect(var('FOO', 'foo', true)).to be_secure
    end
  end

  describe 'echo?' do
    it 'returns true for other vars' do
      expect(var(:FOO, 'foo')).to be_echo
    end

    it 'returns false for internal vars' do
      expect(var(:TRAVIS_FOO, 'foo')).not_to be_echo
    end
  end
end
