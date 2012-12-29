require 'spec_helper'

describe Travis::Build::Script::C do
  let(:data) { PAYLOADS[:push].deep_clone }

  subject { described_class.new(data).compile }

  before :each do
    executable 'configure'
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
end
