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
      should set 'CXX', 'g++'
    end

    it 'sets CC to gcc' do
      should set 'CC', 'gcc'
    end
  end

  describe 'gcc given as compiler' do
    before :each do
      data['config']['compiler'] = 'gcc'
    end

    it 'sets CXX to g++' do
      should set 'CXX', 'g++'
    end

    it 'sets CC to gcc' do
      should set 'CC', 'gcc'
    end
  end

  describe 'g++ given as compiler' do
    before :each do
      data['config']['compiler'] = 'g++'
    end

    it 'sets CXX to g++' do
      should set 'CXX', 'g++'
    end

    it 'sets CC to gcc' do
      should set 'CC', 'gcc'
    end
  end

  describe 'clang given as compiler' do
    before :each do
      data['config']['compiler'] = 'clang'
    end

    it 'sets CXX to clang' do
      should set 'CXX', 'clang++'
    end

    it 'sets CC to clang if clang given as compiler' do
      should set 'CC', 'clang'
    end
  end

  describe 'clang++ given as compiler' do
    before :each do
      data['config']['compiler'] = 'clang++'
    end

    it 'sets CXX to clang' do
      should set 'CXX', 'clang++'
    end

    it 'sets CC to clang' do
      should set 'CC', 'clang'
    end
  end

  it 'runs gcc --version' do
    data['config']['compiler'] = 'gcc'
    should announce 'gcc --version'
  end

  it 'runs ./configure && make && make test' do
    should run 'echo $ ./configure && make && make test'
    should run 'configure', log: true
    should run 'make', log: true
    should run 'make test', log: true, timeout: timeout_for(:script)
  end

  describe :cache_slug do
    subject { described_class.new(data, options) }
    its(:cache_slug) { should be == 'cache--compiler-gpp' }
  end
end
