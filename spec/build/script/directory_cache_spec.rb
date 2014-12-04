require 'spec_helper'

describe Travis::Build::Script::DirectoryCache, :sexp do
  let(:options) { { fetch_timeout: 20, push_timeout: 30, type: 's3', s3: { bucket: 's3_bucket', secret_access_key: 's3_secret_access_key', access_key_id: 's3_access_key_id' } } }
  let(:data)    { payload_for(:push, :ruby, config: config, cache_options: options) }
  let(:sh)      { Travis::Shell::Builder.new }
  let(:sexp)    { script.sexp }
  let(:script)  { Travis::Build.script(data) }
  let(:cache)   { script.directory_cache }

  it_behaves_like 'compiled script' do
    let(:config) { { cache: { directories: ['foo'] } } }
    let(:cmds)   { ['cache.1', 'cache.2', 'casher fetch', 'casher add', 'casher push'] }
  end

  describe 'with no caching enabled' do
    let(:config) { {} }
    it { expect(script).not_to be_use_directory_cache }
    it { expect(cache).to be_a(Travis::Build::Script::DirectoryCache::Noop) }
  end

  describe 'with caching enabled, but config missing' do
    let(:config)  { { cache: { directories: ['foo'] } } }
    let(:options) { { type: 's3' } }
    it { expect(cache).to be_a(Travis::Build::Script::DirectoryCache::Noop) }
  end

  describe 'uses S3 with caching enabled' do
    let(:config) { { cache: { directories: ['foo'] } } }
    it { expect(script).to be_use_directory_cache }
    it { expect(cache).to be_a(Travis::Build::Script::DirectoryCache::S3) }
    # it { store_example 'directory caching' }
  end

  # not quite sure where to put this atm, but there probably should be tests
  # specific to bundler caching
  describe 'with bundler caching enabled' do
    let(:config) { { cache: 'bundler', bundler_args: '--path=foo/bar' } }
    it { expect(sexp).to include_sexp [:cmd, 'bundle clean', echo: true] }
    # it { store_example 'bundler caching' }
  end
end
