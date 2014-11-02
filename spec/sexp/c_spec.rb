require 'spec_helper'

describe Travis::Build::Script::C, :sexp do
  let(:data)   { payload_for(:push, :c) }
  let(:script) { described_class.new(data) }
  subject      { script.sexp }

  it_behaves_like 'compiled script' do
    let(:code) { ['TRAVIS_LANGUAGE=c', './configure && make && make test'] }
  end

  it_behaves_like 'a build script sexp'

  it 'sets CC' do
    should include_sexp [:export, ['CC', 'gcc'], echo: true]
  end

  it 'announces gcc --version' do
    should include_sexp [:cmd, 'gcc --version', echo: true]
  end

  it 'runs ./configure && make && make test' do
    should include_sexp [:cmd, './configure && make && make test', echo: true, timing: true]
  end

  describe '#cache_slug' do
    subject { described_class.new(data).cache_slug }
    it { should eq('cache--compiler-gcc') }
  end
end

