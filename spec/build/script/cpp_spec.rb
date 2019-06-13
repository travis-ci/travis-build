require 'spec_helper'

describe Travis::Build::Script::Cpp, :sexp do
  let(:data)   { payload_for(:push, :cpp) }
  let(:script) { described_class.new(data) }
  subject      { script.sexp }
  it           { store_example }

  it_behaves_like 'a bash script'

  it_behaves_like 'compiled script' do
    let(:code) { ['TRAVIS_LANGUAGE=cpp'] }
    let(:cmds) { ['make test'] }
  end

  it_behaves_like 'a build script sexp'

  describe 'no compiler set' do
    before :each do
      data[:config][:compiler] = nil
    end

    it 'sets CC to gcc' do
      should include_sexp [:export, ['CC', 'gcc'], echo: true]
    end

    it 'sets CXX to g++' do
      should include_sexp [:export, ['CXX', 'g++'], echo: true]
    end
  end

  describe 'gcc given as compiler' do
    before :each do
      data[:config][:compiler] = 'gcc'
    end

    it 'sets CC to gcc' do
      should include_sexp [:export, ['CC', 'gcc'], echo: true]
    end

    it 'sets CXX to g++' do
      should include_sexp [:export, ['CXX', 'g++'], echo: true]
    end
  end

  describe 'g++ given as compiler' do
    before :each do
      data[:config][:compiler] = 'g++'
    end

    it 'sets CC to gcc' do
      should include_sexp [:export, ['CC', 'gcc'], echo: true]
    end

    it 'sets CXX to g++' do
      should include_sexp [:export, ['CXX', 'g++'], echo: true]
    end
  end
  
  describe 'g++-4.9 given as compiler' do
      before :each do
          data[:config][:compiler] = 'g++-4.9'
      end
      
      it 'sets CC to gcc-4.9' do
          should include_sexp [:export, ['CC', 'gcc-4.9'], echo: true]
      end
      
      it 'sets CXX to g++-4.9' do
          should include_sexp [:export, ['CXX', 'g++-4.9'], echo: true]
      end
  end

  describe 'clang given as compiler' do
    before :each do
      data[:config][:compiler] = 'clang'
    end

    it 'sets CC to clang' do
      should include_sexp [:export, ['CC', 'clang'], echo: true]
    end

    it 'sets CXX to clang++' do
      should include_sexp [:export, ['CXX', 'clang++'], echo: true]
    end
  end

  describe 'clang++ given as compiler' do
    before :each do
      data[:config][:compiler] = 'clang++'
    end

    it 'sets CC to clang' do
      should include_sexp [:export, ['CC', 'clang'], echo: true]
    end

    it 'sets CXX to clang++' do
      should include_sexp [:export, ['CXX', 'clang++'], echo: true]
    end
  end
  
  describe 'clang++-3.7 given as compiler' do
      before :each do
          data[:config][:compiler] = 'clang++-3.7'
      end
      
      it 'sets CC to clang-3.7' do
          should include_sexp [:export, ['CC', 'clang-3.7'], echo: true]
      end
      
      it 'sets CXX to clang++-3.7' do
          should include_sexp [:export, ['CXX', 'clang++-3.7'], echo: true]
      end
  end

  it 'runs g++ --version' do
    data[:config][:compiler] = 'g++'
    should include_sexp [:cmd, 'g++ --version', echo: true]
  end

  it 'runs ./configure && make && make test' do
    should include_sexp [:cmd, './configure && make && make test', echo: true, timing: true]
  end

  describe '#cache_slug' do
    subject { described_class.new(data).cache_slug }
    it { is_expected.to eq("cache-#{CACHE_SLUG_EXTRAS}--compiler-gpp") }
  end
end
