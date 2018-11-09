require 'spec_helper'

describe Travis::Build::Env::Var do
  def parse(line)
    described_class.parse(line)
  end

  def var(key, value, options = {})
    described_class.new(key, value, options)
  end

  describe 'parse' do
    it 'parses SECURE FOO=foo BAR=bar' do
      expect(parse('SECURE FOO=foo BAR=bar')).to eq([["FOO", "foo", secure: true], ["BAR", "bar", secure: true]])
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

    it "parses FOO= BAR=bar" do
      expect(parse("FOO= BAR=bar")).to eq([['FOO', ""], ['BAR', 'bar']])
    end

    it "assigns empty strings" do
      expect(parse("FOO= BAR=")).to eq([['FOO', ""], ['BAR', '']])
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

    it 'parses FOO="$var" BAR="bar bar"' do
      expect(parse('FOO="$var" BAR="bar bar"')).to eq([['FOO', '"$var"'], ['BAR', '"bar bar"']])
    end

    it 'parses FOO=$var BAR="bar bar"' do
      expect(parse('FOO=$var BAR="bar bar"')).to eq([['FOO', '$var'], ['BAR', '"bar bar"']])
    end

    it 'preserves $()' do
      expect(parse('FOO=$(command) BAR="bar bar"')).to eq([['FOO', '$(command)'], ['BAR', '"bar bar"']])
    end

    it 'preserves ${NAME}' do
      expect(parse('FOO=${NAME} BAR="bar bar"')).to eq([['FOO', '${NAME}'], ['BAR', '"bar bar"']])
    end

    it 'preserves ${NAME}STUFF' do
      expect(parse('FOO=${NAME}STUFF BAR="bar bar"')).to eq([['FOO', '${NAME}STUFF'], ['BAR', '"bar bar"']])
    end

    it 'preserves $' do
      expect(parse('FOO=$ BAR="bar bar"')).to eq([['FOO', '$'], ['BAR', '"bar bar"']])
    end

    it 'preserves embedded =' do
      expect(parse('FOO=comm=bar BAR="bar bar"')).to eq([['FOO', 'comm=bar'], ['BAR', '"bar bar"']])
    end

    it 'ignores unquoted bare word' do
      expect(parse('FOO=$comm bar BAR="bar bar"')).to eq([['FOO', '$comm'], ['BAR', '"bar bar"']])
    end

    it 'parses quoted string, with escaped end-quote mark inside' do
      expect(parse('FOO="foo\\"bar" BAR="bar bar"')).to eq([['FOO', '"foo\\"bar"'], ['BAR', '"bar bar"']])
    end

    it 'allow $ in the middle' do
      expect(parse('APP_URL=http://$APP_HOST:8080 BAR="bar bar"')).to eq([['APP_URL', 'http://$APP_HOST:8080'], ['BAR', '"bar bar"']])
    end

    it 'allow ` in the middle' do
      expect(parse('PATH=FOO:`pwd`/bin BAR="bar bar"')).to eq([['PATH', 'FOO:`pwd`/bin'], ['BAR', '"bar bar"']])
    end

    it '`` with a space inside' do
      expect(parse('KERNEL=`uname -r` BAR="bar bar"')).to eq([['KERNEL', '`uname -r`'], ['BAR', '"bar bar"']])
    end

    it 'some stuff, followed by `` with a space inside' do
      expect(parse('KERNEL=a`uname -r` BAR="bar bar"')).to eq([['KERNEL', 'a`uname -r`'], ['BAR', '"bar bar"']])
    end

    it 'some stuff, followed by $() with a space inside' do
      expect(parse('KERNEL=a$(uname -r) BAR="bar bar"')).to eq([['KERNEL', 'a$(uname -r)'], ['BAR', '"bar bar"']])
    end

    it 'some stuff, followed by "" with a space inside' do
      expect(parse('KERNEL=a"$(find \"${TRAVIS_HOME}\" {} \;)" BAR="bar bar"')).to eq([['KERNEL', 'a"$(find \\"${TRAVIS_HOME}\\" {} \\;)"'], ['BAR', '"bar bar"']])
    end

    it 'handle space after the initial $ in ()' do
      expect(parse('CAT_VERSION=$(cat VERSION)')).to eq([['CAT_VERSION', '$(cat VERSION)']])
    end

    it 'env var can start with SECURE' do
      expect(parse('SECURE_VAR=value BAR="bar bar"')).to eq([['SECURE_VAR', 'value'], ['BAR', '"bar bar"']])
    end
  end

  describe 'secure?' do
    it 'returns true if the var name starts with SECURE' do
      args = parse('SECURE FOO=foo').first
      expect(var(*args)).to be_secure
    end

    it 'returns true if var is created with secure argument' do
      expect(var('FOO', 'foo', secure: true)).to be_secure
    end
  end

  describe 'echo?' do
    it 'returns true for other vars' do
      expect(var(:FOO, 'foo', type: :settings)).to be_echo
    end

    it 'returns false for internal vars' do
      expect(var(:TRAVIS_FOO, 'foo', type: :builtin)).not_to be_echo
    end
  end
end
