require 'spec_helper'

describe Travis::Build::Script::DirectoryCache::S3, :sexp do
  FETCH_URL  = "https://s3_bucket.s3.amazonaws.com/42/%s/example.tbz?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=s3_access_key_id%%2F19700101%%2Fus-east-1%%2Fs3%%2Faws4_request&X-Amz-Date=19700101T000010Z"
  SIGNED_URL = "%s&X-Amz-Expires=20&X-Amz-Signature=%s&X-Amz-SignedHeaders=host"

  def url_for(branch)
    FETCH_URL % branch
  end

  def signed_url_for(branch, signature)
    Shellwords.escape(SIGNED_URL % [url_for(branch), signature])
  end

  let(:master_fetch_signature) { "163b2a236fcfda37d58c1d50c27d86fbd04efb4a6d97219134f71854e3e0383b" }
  let(:fetch_signature)        { master_fetch_signature }
  let(:push_signature)         { "926885a758f00d51eaad281522a26cf7151fdd530aa1272c1d8c607c2e778570" }

  let(:url)           { url_for(branch) }
  let(:fetch_url)     { Shellwords.escape "#{url}&X-Amz-Expires=20&X-Amz-Signature=#{fetch_signature}&X-Amz-SignedHeaders=host" }
  let(:push_url)      { Shellwords.escape "#{url}&X-Amz-Expires=30&X-Amz-Signature=#{push_signature}&X-Amz-SignedHeaders=host" }

  let(:s3_options)    { { bucket: 's3_bucket', secret_access_key: 's3_secret_access_key', access_key_id: 's3_access_key_id' } }
  let(:cache_options) { { fetch_timeout: 20, push_timeout: 30, type: 's3', s3: s3_options } }
  let(:data)          { PAYLOADS[:push].deep_merge(config: config, cache_options: cache_options, job: { branch: branch, pull_request: pull_request }) }
  let(:config)        { {} }
  let(:pull_request)  { nil }
  let(:branch)        { 'master' }
  let(:sh)            { Travis::Shell::Builder.new }
  let(:cache)         { described_class.new(sh, Travis::Build::Data.new(data), 'ex a/mple', Time.at(10)) }
  let(:subject)       { sh.to_sexp }

  describe 'install' do
    before { cache.install }

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

    describe 'passing a casher branch' do
      let(:config) { { cache: { branch: 'foo' } } }
      it { should include_sexp [:cmd, 'curl https://raw.githubusercontent.com/travis-ci/casher/foo/bin/casher -L -o $CASHER_DIR/bin/casher -s --fail', retry: true, display: 'Installing caching utilities'] }
    end
  end

  describe 'fetch' do
    before { cache.fetch }
    it { should include_sexp [:cmd, "rvm 1.9.3 --fuzzy do $CASHER_DIR/bin/casher fetch #{fetch_url}"] }
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
    let(:branch)          { 'featurefoo' }
    let(:fetch_signature) { 'cbce59b97e29ba90e1810a9cbedc1d5cd76df8235064c0016a53dea232124d60' }
    let(:push_signature)  { '256ffe8e059f07c9d4e3f2491068fe22ad92722d120590e05671467fb5fda252' }
    let(:fallback_url)    { signed_url_for('master', master_fetch_signature) }

    describe 'fetch' do
      before { cache.fetch }
      it { should include_sexp [:cmd, "rvm 1.9.3 --fuzzy do $CASHER_DIR/bin/casher fetch #{fetch_url} #{fallback_url}"] }
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

  describe 'on a pull request' do
    let(:pull_request)    { 15 }
    let(:fetch_signature) { 'b1db673b9a243ecbc792fd476c4f5b45462449dd73b65987d11710b42f180773' }
    let(:push_signature)  { '863f53cbb1cff7780c5a53689cd849f0b6032e30de428515fe181d65be20e13e' }
    let(:url)             { url_for("PR.#{pull_request}") }
    let(:fallback_url)    { signed_url_for('master', master_fetch_signature) }

    describe 'fetch' do
      before { cache.fetch }
      it { should include_sexp [:cmd, "rvm 1.9.3 --fuzzy do $CASHER_DIR/bin/casher fetch #{fetch_url} #{fallback_url}"] }
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

  describe 'on a pull request to a different branch' do
    let(:pull_request)    { 15 }
    let(:branch)          { 'foo' }
    let(:fetch_signature) { 'b1db673b9a243ecbc792fd476c4f5b45462449dd73b65987d11710b42f180773' }
    let(:push_signature)  { '863f53cbb1cff7780c5a53689cd849f0b6032e30de428515fe181d65be20e13e' }
    let(:url)             { url_for("PR.#{pull_request}") }
    let(:fallback_url)    { signed_url_for('master', master_fetch_signature) }
    let(:branch_fallback_url) { signed_url_for('foo', 'd72269ea040415d06cea7382c25f211f05b5a701c68299c03bbecd861a5e820b') }

    describe 'fetch' do
      before { cache.fetch }
      it { should include_sexp [:cmd, "rvm 1.9.3 --fuzzy do $CASHER_DIR/bin/casher fetch #{fetch_url} #{branch_fallback_url} #{fallback_url}"] }
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
