require 'spec_helper'

describe Travis::Build::Script::C, :sexp do
  let(:data)   { payload_for(:push, :c, config: config) }
  let(:config) { {} }
  let(:script) { described_class.new(data) }
  subject      { script.sexp }
  it           { store_example }

  it_behaves_like 'a bash script'

  it_behaves_like 'compiled script' do
    let(:code) { ['TRAVIS_LANGUAGE=c'] }
    let(:cmds) { ['./configure && make && make test'] }
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

  context "when clang is requested" do
    let(:config) { { compiler: 'clang' } }
    it { store_example(name: 'clang') }

    it 'adds LLVM apt source' do
      should include_sexp [:cmd, "echo \"deb https://apt.llvm.org/$(lsb_release -cs)/ llvm-toolchain-$(lsb_release -cs) main\"  | sudo tee /etc/apt/sources.list.d/llvm.list >/dev/null"]
    end
  end

  context "when clang-7 is requested" do
    let(:config) { { compiler: 'clang-7' } }
    it { store_example(name: 'clang-7') }

    it 'adds LLVM apt source' do
      should include_sexp [:cmd, "echo \"deb https://apt.llvm.org/$(lsb_release -cs)/ llvm-toolchain-$(lsb_release -cs)-7 main\"  | sudo tee /etc/apt/sources.list.d/llvm.list >/dev/null"]
    end
  end

  describe '#cache_slug' do
    subject { described_class.new(data).cache_slug }
    it { should eq("cache-#{CACHE_SLUG_EXTRAS}--compiler-gcc") }
  end

  context 'when cache requires ccache' do
    let(:config) { { cache: 'ccache' } }

    describe '#export' do
      it 'prepends /usr/lib/ccache to PATH' do
        should include_sexp [:export, ['PATH', '/usr/lib/ccache:$PATH'], echo: true]
      end
    end
  end
end
