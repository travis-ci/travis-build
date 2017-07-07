require 'spec_helper'

describe Travis::Build do
  describe '.by_lang' do

    {
      Android: ['android'],
      C: ['c'],
      Clojure: ['clojure'],
      Cpp: ['cpp', 'c++', 'cplusplus'],
      Crystal: ['crystal'],
      Csharp: ['csharp'],
      D: ['d'],
      Dart: ['dart'],
      Erlang: ['erlang'],
      Generic: ['generic', 'bash', 'sh', 'shell', 'minimal'],
      Go: ['go'],
      Groovy: ['groovy'],
      Haskell: ['haskell'],
      Haxe: ['haxe'],
      Julia: ['julia'],
      Nix: ['nix'],
      NodeJs: ['node_js'],
      ObjectiveC: ['objective_c', 'objective-c', 'swift'],
      Perl6: ['perl6'],
      Perl: ['perl'],
      Php: ['php'],
      PureJava: ['java', 'java-anything'],
      Python: ['python'],
      R: ['r'],
      Ruby: ['ruby'],
      Rust: ['rust'],
      Scala: ['scala'],
      Smalltalk: ['smalltalk'],
    }.each do |script_type, langs|
      langs.each do |lang|
        it "returns #{script_type} for #{lang}" do
          expect(described_class.by_lang(lang)).to eq(Travis::Build::Script.const_get(script_type))
        end
      end
    end

    it 'returns Ruby for unknown languages' do
      expect(described_class.by_lang('foo')).to eq(Travis::Build::Script::Ruby)
    end

  end
end
