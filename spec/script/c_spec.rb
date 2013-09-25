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
    should set 'CC', 'gcc'
  end

  it 'announces gcc --version' do
    should announce 'gcc --version', echo: true, log: true
  end

  it 'runs ./configure && make && make test' do
    should run 'echo $ ./configure && make && make test'
    should run 'configure', log: true
    should run 'make', log: true
    should run 'make test', log: true, timeout: timeout_for(:script)
  end

  describe :cache_slug do
    subject { described_class.new(data, options) }
    its(:cache_slug) { should be == 'cache--compiler-gcc' }
  end
end
