require 'spec_helper'

describe Travis::Build::Script::C, :sexp do
  let(:data)   { payload_for(:push, :c) }
  let(:script) { described_class.new(data) }
  subject      { script.sexp }
  it           { store_example }

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

  it 'sets CCACHE_DISABLE to true' do
    should include_sexp [:export, ['CCACHE_DISABLE', 'true']]
  end

  describe '#cache_slug' do
    subject { described_class.new(data).cache_slug }
    it { should eq('cache--compiler-gcc') }
  end

  describe 'ccache caching' do
    let(:options) { { fetch_timeout: 20, push_timeout: 30, type: 's3', s3: { bucket: 's3_bucket', secret_access_key: 's3_secret_access_key', access_key_id: 's3_access_key_id' } } }
    let(:data)    { payload_for(:push, :c, config: { cache: 'ccache' }, cache_options: options) }

    it 'sets CCACHE_DISABLE to false' do
      should include_sexp [:export, ['CCACHE_DISABLE', 'false']]
    end
  end
end

