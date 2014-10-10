require 'spec_helper'

describe Travis::Build do
  describe 'by_lang' do
    it 'maps anything java-ish to PureJava' do
      %w(java-woot java7 javaZOMBIES).each do |lang|
        expect(subject.by_lang(lang)).to eq(Travis::Build::Script::PureJava)
      end
    end

    it 'maps c++, cpp, and cplusplus to Cpp' do
      %w(c++ cpp cplusplus).each do |lang|
        expect(subject.by_lang(lang)).to eq(Travis::Build::Script::Cpp)
      end
    end

    it 'maps objective-c to ObjectiveC' do
      expect(subject.by_lang('objective-c')).to eq(Travis::Build::Script::ObjectiveC)
    end

    it 'maps bash, sh, and shell to Generic' do
      %w(bash sh shell).each do |lang|
        expect(subject.by_lang(lang)).to eq(Travis::Build::Script::Generic)
      end
    end

    it 'maps known languages to their implementations' do
      %w(android c cpp clojure erlang go groovy haskell node_js perl php python rust scala).each do |lang|
        expect(subject.by_lang(lang)).to_not eq(Travis::Build::Script::Ruby)
      end
    end

    it 'maps unknown languages to Ruby' do
      %w(brainfudge objective-d rubby).each do |lang|
        expect(subject.by_lang(lang)).to eq(Travis::Build::Script::Ruby)
      end
    end
  end
end
