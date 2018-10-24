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

  describe 'with timeout' do
    let(:config) { { cache: { timeout: 1 } } }
    it { expect(sexp).to include_sexp [:export, ['CASHER_TIME_OUT', 1]] }
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
  end

  describe 'uses S3 with caching enabled and before_cache defined' do
    let(:cmd)    { 'echo foo'}
    let(:config) { { cache: { directories: ['foo'] }, before_cache: cmd } }
    it { expect(script).to be_use_directory_cache }
    it { expect(cache).to be_a(Travis::Build::Script::DirectoryCache::S3) }
    it { expect(sexp).to include_sexp [:cmd, cmd, echo: true, timing: true] }
  end

  # not quite sure where to put this atm, but there probably should be tests
  # specific to bundler caching
  describe 'bundler caching' do
    describe 'with explicit path' do
      let(:config) { { cache: 'bundler', bundler_args: '--path=foo/bar' } }
      it { expect(sexp).to include_sexp [:cmd, 'bundle clean', echo: true] }
      it { expect(sexp).to include_sexp [:cmd, 'bundle install --path=foo/bar', assert: true, echo: true, timing: true, retry: true] }
      it { expect(sexp).to include_sexp [:cmd, 'rvm $(travis_internal_ruby) --fuzzy do $CASHER_DIR/bin/casher add ./foo/bar', timing: true] }
    end

    describe 'with implicit path' do
      let(:config) { { cache: 'bundler' } }
      it { expect(sexp).to include_sexp [:cmd, 'bundle install --jobs=3 --retry=3 --deployment --path=${BUNDLE_PATH:-vendor/bundle}', assert: true, echo: true, timing: true, retry: true] }
      it { expect(sexp).to include_sexp [:cmd, 'bundle clean', echo: true] }
      it { expect(sexp).to include_sexp [:cmd, 'rvm $(travis_internal_ruby) --fuzzy do $CASHER_DIR/bin/casher add ${BUNDLE_PATH:-./vendor/bundle}', timing: true] }
    end

    describe 'with implicit path, but gemfile in a subdirectory' do
      let(:config) { { cache: 'bundler', gemfile: 'foo/Gemfile' } }
      it { expect(sexp).to include_sexp [:cmd, 'bundle install --jobs=3 --retry=3 --deployment --path=${BUNDLE_PATH:-vendor/bundle}', assert: true, echo: true, timing: true, retry: true] }
      it { expect(sexp).to include_sexp [:cmd, 'bundle clean', echo: true] }
      it { expect(sexp).to include_sexp [:cmd, 'rvm $(travis_internal_ruby) --fuzzy do $CASHER_DIR/bin/casher add ${BUNDLE_PATH:-foo/vendor/bundle}', timing: true] }
    end

    describe 'with explicit path, but gemfile in a subdirectory' do
      let(:config) { { cache: 'bundler', gemfile: 'foo/Gemfile', bundler_args: '--path=foo/bar' } }
      it { expect(sexp).to include_sexp [:cmd, 'bundle clean', echo: true] }
      it { expect(sexp).to include_sexp [:cmd, 'bundle install --path=foo/bar', assert: true, echo: true, timing: true, retry: true] }
      it { expect(sexp).to include_sexp [:cmd, 'rvm $(travis_internal_ruby) --fuzzy do $CASHER_DIR/bin/casher add foo/foo/bar', timing: true] }
    end
  end

  describe '#fetch_url' do
    context 'Given "cache: bundler"' do
      let(:config) { { cache: 'bundler' } }
      let(:file_name) { URI(cache.fetch_url).path.split('/').last }

      it { expect(file_name).to eq 'cache--rvm-default--gemfile-Gemfile.tgz' }

      context 'when looking for cache with extra information' do
        let(:file_name) { URI(cache.fetch_url('foo', true)).path.split('/').last }

        it { expect(file_name).to eq "cache-#{CACHE_SLUG_EXTRAS}--rvm-default--gemfile-Gemfile.tgz" }
      end
    end
  end

  describe '#push_url' do
    context 'Given "cache: bundler"' do
      let(:config) { { cache: 'bundler' } }
      let(:file_name) { URI(cache.push_url).path.split('/').last }

      it { expect(file_name).to eq "cache-#{CACHE_SLUG_EXTRAS}--rvm-default--gemfile-Gemfile.tgz" }

      context 'and "os: osx"' do
        let(:config) { { cache: 'bundler', os: 'osx' } }

        it { expect(file_name).to eq "cache-#{CACHE_SLUG_EXTRAS.gsub('linux','osx')}--rvm-default--gemfile-Gemfile.tgz" }
      end
    end
  end
end
