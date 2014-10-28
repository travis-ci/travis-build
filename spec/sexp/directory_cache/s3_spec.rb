require 'spec_helper'

describe Travis::Build::Script::DirectoryCache::S3, :sexp do
  def url_for(branch)
    pattern = "https://s3_bucket.s3.amazonaws.com/42/%s/example.tbz?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=s3_access_key_id%%2F19700101%%2Fus-east-1%%2Fs3%%2Faws4_request&X-Amz-Date=19700101T000010Z"
    pattern % branch
  end

  let(:global_fallback)        { "https://s3_bucket.s3.amazonaws.com/42/example.tbz\\?X-Amz-Algorithm\\=AWS4-HMAC-SHA256\\&X-Amz-Credential\\=s3_access_key_id\\%2F19700101\\%2Fus-east-1\\%2Fs3\\%2Faws4_request\\&X-Amz-Date\\=19700101T000010Z\\&X-Amz-Expires\\=20\\&X-Amz-Signature\\=7f206e62deecd81668ca0093f051aeeaaff5c7f53dcf74186c468e4eef3c1e75\\&X-Amz-SignedHeaders\\=host" }
  let(:master_fetch_signature) { "163b2a236fcfda37d58c1d50c27d86fbd04efb4a6d97219134f71854e3e0383b" }
  let(:fetch_signature)        { master_fetch_signature }
  let(:push_signature)         { "926885a758f00d51eaad281522a26cf7151fdd530aa1272c1d8c607c2e778570" }

  let(:url)           { url_for(branch) }
  let(:fetch_url)     { Shellwords.escape "#{url}&X-Amz-Expires=20&X-Amz-Signature=#{fetch_signature}&X-Amz-SignedHeaders=host" }
  let(:push_url)      { Shellwords.escape "#{url}&X-Amz-Expires=30&X-Amz-Signature=#{push_signature}&X-Amz-SignedHeaders=host" }

  let(:s3_options)    { { bucket: 's3_bucket', secret_access_key: 's3_secret_access_key', access_key_id: 's3_access_key_id' } }
  let(:cache_options) { { fetch_timeout: 20, push_timeout: 30, type: 's3', s3: s3_options } }
  let(:data)          { PAYLOADS[:push].deep_merge(config: config, cache_options: cache_options, job: { branch: branch }) }
  let(:config)        { {} }
  let(:branch)        { 'master' }
  let(:sh)            { Travis::Shell::Builder.new }
  let(:cache)         { described_class.new(sh, Travis::Build::Data.new(data), 'ex a/mple', Time.at(10)) }
  let(:subject)       { sh.to_sexp }

  describe 'install' do
    before { cache.install }

    # it { should include_sexp [:echo, 'Installing cache utilities'] }

    describe 'uses casher production in default mode' do
      it { should include_sexp [:export, ['CASHER_DIR', '$HOME/.casher'], echo: true] }
      it { should include_sexp [:mkdir, '$CASHER_DIR/bin', recursive: true] }
      it { should include_sexp [:cmd,  'curl https://raw.githubusercontent.com/travis-ci/casher/production/bin/casher -L -o $CASHER_DIR/bin/casher -s --fail', retry: true, display: 'Installing caching utilities'] }
      it { should include_sexp [:cmd, '[ $? -ne 0 ] && echo \'Failed to fetch casher from GitHub, disabling cache.\' && echo > $CASHER_DIR/bin/casher'] }
    end

    describe 'uses casher master in edge mode' do
      let(:config) { { cache: { edge: true } } }
      it { should include_sexp [:cmd, 'curl https://raw.githubusercontent.com/travis-ci/casher/master/bin/casher -L -o $CASHER_DIR/bin/casher -s --fail', retry: true, display: 'Installing caching utilities'] }
    end
  end

  describe 'fetch' do
    before { cache.fetch }
    it { should include_sexp [:cmd, "rvm 1.9.3 --fuzzy do $CASHER_DIR/bin/casher fetch #{fetch_url} #{global_fallback}"] }
  end

  describe 'add' do
    before { cache.add('/foo/bar') }
    it { should include_sexp [:cmd, 'rvm 1.9.3 --fuzzy do $CASHER_DIR/bin/casher add /foo/bar'] }
  end

  describe 'push' do
    before { cache.push }
    it { should include_sexp [:cmd, "rvm 1.9.3 --fuzzy do $CASHER_DIR/bin/casher push #{push_url}"] }
  end

  describe 'on a different branch' do
    let(:fetch_signature) { 'cbce59b97e29ba90e1810a9cbedc1d5cd76df8235064c0016a53dea232124d60' }
    let(:push_signature)  { '256ffe8e059f07c9d4e3f2491068fe22ad92722d120590e05671467fb5fda252' }
    let(:fallback_url)    { Shellwords.escape "#{url_for('master')}&X-Amz-Expires=20&X-Amz-Signature=#{master_fetch_signature}&X-Amz-SignedHeaders=host" }
    let(:branch)          { 'featurefoo' }

    describe 'fetch' do
      before { cache.fetch }
      it { should include_sexp [:cmd, "rvm 1.9.3 --fuzzy do $CASHER_DIR/bin/casher fetch #{fetch_url} #{fallback_url} #{global_fallback}"] }
    end

    describe 'add' do
      before { cache.add('/foo/bar') }
      it { should include_sexp [:cmd, 'rvm 1.9.3 --fuzzy do $CASHER_DIR/bin/casher add /foo/bar'] }
    end

    describe 'push' do
      before { cache.push }
      it { should include_sexp [:cmd, "rvm 1.9.3 --fuzzy do $CASHER_DIR/bin/casher push #{push_url}"] }
    end
  end

  describe 'signatures' do
    it "works with Amazon's example" do
      key_pair = described_class::KeyPair.new('AKIAIOSFODNN7EXAMPLE', 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY')
      location = described_class::Location.new('https', 'us-east-1', 'examplebucket', '/test.txt')
      signature = described_class::AWS4Signature.new(key_pair, 'GET', location, 86400, Time.gm(2013, 5, 24))

      expect(signature.to_uri.query_values['X-Amz-Signature']).to eq('aeeed9bbccd4d02ee5c0109b86d86835f995330da4c265957d157751f604d404')
    end
  end
end
