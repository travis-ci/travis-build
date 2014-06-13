require 'spec_helper'

describe Travis::Build::Script::Cpp do
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

  describe 'no compiler set' do
    before :each do
      data['config']['compiler'] = nil
    end

    it 'sets CXX to g++' do
      is_expected.to set 'CXX', 'g++'
    end

    it 'sets CC to gcc' do
      is_expected.to set 'CC', 'gcc'
    end
  end

  describe 'gcc given as compiler' do
    before :each do
      data['config']['compiler'] = 'gcc'
    end

    it 'sets CXX to g++' do
      is_expected.to set 'CXX', 'g++'
    end

    it 'sets CC to gcc' do
      is_expected.to set 'CC', 'gcc'
    end
  end

  describe 'g++ given as compiler' do
    before :each do
      data['config']['compiler'] = 'g++'
    end

    it 'sets CXX to g++' do
      is_expected.to set 'CXX', 'g++'
    end

    it 'sets CC to gcc' do
      is_expected.to set 'CC', 'gcc'
    end
  end

  describe 'clang given as compiler' do
    before :each do
      data['config']['compiler'] = 'clang'
    end

    it 'sets CXX to clang' do
      is_expected.to set 'CXX', 'clang++'
    end

    it 'sets CC to clang if clang given as compiler' do
      is_expected.to set 'CC', 'clang'
    end
  end

  describe 'clang++ given as compiler' do
    before :each do
      data['config']['compiler'] = 'clang++'
    end

    it 'sets CXX to clang' do
      is_expected.to set 'CXX', 'clang++'
    end

    it 'sets CC to clang' do
      is_expected.to set 'CC', 'clang'
    end
  end

  it 'runs gcc --version' do
    data['config']['compiler'] = 'gcc'
    is_expected.to announce 'gcc --version'
  end

  it 'runs ./configure && make && make test' do
    is_expected.to run 'echo $ ./configure && make && make test'
    is_expected.to run 'configure', log: true
    is_expected.to run 'make', log: true
    is_expected.to run 'make test', log: true
  end

  describe '#cache_slug' do
    subject { described_class.new(data, options).cache_slug }
    it { is_expected.to eq('cache--compiler-gpp') }
  end
end
