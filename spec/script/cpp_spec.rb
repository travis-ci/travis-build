require 'spec_helper'

describe Travis::Build::Script::Cpp do
  let(:options) { { logs: { build: true, state: true } } }
  let(:data)    { PAYLOADS[:push].deep_clone }

  subject { described_class.new(data, options).compile }

  before :each do
    executable 'configure'
  end

  it_behaves_like 'a build script'

  it 'sets CXX to g++ if gcc given as compiler' do
    data['config']['compiler'] = 'gcc'
    should set 'CXX', 'g++'
  end

  it 'sets CXX to g++ if g++ given as compiler' do
    data['config']['compiler'] = 'g++'
    should set 'CXX', 'g++'
  end

  it 'sets CXX to clang if clang given as compiler' do
    data['config']['compiler'] = 'clang'
    should set 'CXX', 'clang++'
  end

  it 'sets CXX to clang if clang++ given as compiler' do
    data['config']['compiler'] = 'clang++'
    should set 'CXX', 'clang++'
  end

  it 'sets CXX to g++ by default' do
    data['config']['compiler'] = 'compiler'
    should set 'CXX', 'g++'
  end

  it 'sets CC to gcc if gcc given as compiler' do
    data['config']['compiler'] = 'gcc'
    should set 'CC', 'gcc'
  end

  it 'sets CC to gcc if g++ given as compiler' do
    data['config']['compiler'] = 'g++'
    should set 'CC', 'gcc'
  end

  it 'sets CC to clang if clang given as compiler' do
    data['config']['compiler'] = 'clang'
    should set 'CC', 'clang'
  end

  it 'sets CC to clang if clang++ given as compiler' do
    data['config']['compiler'] = 'clang++'
    should set 'CC', 'clang'
  end

  it 'sets CC to gcc by default' do
    data['config']['compiler'] = 'compiler'
    should set 'CC', 'gcc'
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
end
