require 'spec_helper'

describe Travis::Build::Script::C do
  let(:options) { { logs: { build: false, state: false } } }
  let(:data)    { PAYLOADS[:push].deep_clone }

  subject { described_class.new(data, options).compile }

  before :each do
    executable 'configure'
  end

  after :all do
    store_example
  end

  it_behaves_like 'a build script'

  it 'sets CC' do
    is_expected.to travis_cmd 'export CC=gcc', echo: true
  end

  it 'announces gcc --version' do
    is_expected.to announce 'gcc --version', echo: true
  end

  it 'runs ./configure && make && make test' do
    is_expected.to travis_cmd './configure && make && make test', echo: true, timing: true
  end

  describe '#cache_slug' do
    subject { described_class.new(data, options).cache_slug }
    it { is_expected.to eq('cache--compiler-gcc') }
  end
end
