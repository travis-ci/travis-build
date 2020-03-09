require 'spec_helper'

describe Travis::Build::Script::Clojure, :sexp do
  let(:data)   { payload_for(:push, :clojure) }
  let(:script) { described_class.new(data) }
  subject      { script.sexp }
  it           { store_example }

  it_behaves_like 'a bash script'

  it_behaves_like 'compiled script' do
    let(:code) { ['TRAVIS_LANGUAGE=clojure'] }
    let(:cmds) { ['lein test'] }
  end

  it_behaves_like 'a build script sexp'
  it_behaves_like 'a jdk build sexp'
  it_behaves_like 'announces java versions'

  describe 'if no lein config given' do
    it { store_example(name: 'no lein config') }

    it 'announces lein version' do
      should include_sexp [:cmd, 'lein version', echo: true]
    end

    it 'installs lein deps' do
      should include_sexp [:cmd, 'lein deps', echo: true, assert: true, retry: true, timing: true]
    end

    it 'runs lein test' do
      should include_sexp [:cmd, 'lein test', echo: true, timing: true]
    end
  end

  describe 'if lein: lein2 given' do
    it { store_example(name: 'lein2 config') }

    before(:each) { data[:config][:lein] = 'lein2' }

    it 'announces lein2 version if lein: lein2 given' do
      should include_sexp [:cmd, 'lein2 version', echo: true]
    end

    it 'installs lein2 deps if lein: lein2 given' do
      should include_sexp [:cmd, 'lein2 deps', echo: true, assert: true, retry: true, timing: true]
    end

    it 'runs lein2 test if lein: lein2 given' do
      should include_sexp [:cmd, 'lein2 test', echo: true, timing: true]
    end
  end

  describe '#cache_slug' do
    subject { described_class.new(data).cache_slug }
    it { is_expected.to eq("cache-#{CACHE_SLUG_EXTRAS}--jdk-default--lein-lein") }
  end
end

