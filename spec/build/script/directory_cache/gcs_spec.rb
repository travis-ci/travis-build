require 'spec_helper'

describe Travis::Build::Script::DirectoryCache::Gcs, :sexp do
  GCS_FETCH_URL  = "https://s3_bucket.storage.googleapis.com/42/%s/example.%s?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=s3_access_key_id%%2F19700101%%2Fus-east-1%%2Fs3%%2Faws4_request&X-Amz-Date=19700101T000010Z"
  GCS_SIGNED_URL = "%s&X-Amz-Expires=20&X-Amz-Signature=%s&X-Amz-SignedHeaders=host"

  def url_for(branch, ext = 'tbz')
    GCS_FETCH_URL % [ branch, ext ]
  end

  def signed_url_for(branch, signature, ext = 'tbz')
    Shellwords.escape(GCS_SIGNED_URL % [url_for(branch, ext), signature])
  end

  let(:master_fetch_signature) { "163b2a236fcfda37d58c1d50c27d86fbd04efb4a6d97219134f71854e3e0383b" }
  let(:master_fetch_signature_tgz) { "742726586b6d8c86bdc9fbe6eb412d63818347ad54b4fd32f2447df97efdc468" }
  let(:fetch_signature)        { master_fetch_signature }
  let(:fetch_signature_tgz)    { master_fetch_signature_tgz }
  let(:push_signature)         { "e7e04f36f46920e9011580d53b16f2fc492094a8b4ec89076411a9d6800cf0ac" }

  let(:url)           { url_for(branch) }
  let(:url_tgz)       { url_for(branch, 'tgz') }
  let(:fetch_url)     { Shellwords.escape "#{url}&X-Amz-Expires=20&X-Amz-Signature=#{fetch_signature}&X-Amz-SignedHeaders=host" }
  let(:fetch_url_tgz) { Shellwords.escape "#{url_tgz}&X-Amz-Expires=20&X-Amz-Signature=#{fetch_signature_tgz}&X-Amz-SignedHeaders=host" }
  let(:push_url)      { Shellwords.escape("#{url}&X-Amz-Expires=30&X-Amz-Signature=#{push_signature}&X-Amz-SignedHeaders=host").gsub(/\.tbz(\?)?/, '.tgz\1') }

  let(:gsc_options)   { { bucket: 's3_bucket', secret_access_key: 's3_secret_access_key', access_key_id: 's3_access_key_id' } }
  let(:cache_options) { { fetch_timeout: 20, push_timeout: 30, type: 'gsc', gcs: gsc_options, signature_version: '2' } }
  let(:data)          { PAYLOADS[:push].deep_merge(config: config, cache_options: cache_options, job: { branch: branch, pull_request: pull_request }) }
  let(:config)        { {} }
  let(:pull_request)  { nil }
  let(:branch)        { 'master' }
  let(:sh)            { Travis::Shell::Builder.new }
  let(:cache)         { described_class.new(sh, Travis::Build::Data.new(data), 'ex a/mple', Time.at(10)) }
  let(:subject)       { sh.to_sexp }

  describe 'validate' do
    before { cache.valid? }

    describe 'with valid s3' do
      it { should_not include_sexp [:echo, 'Worker GCS config missing: bucket name, access key id, secret access key', ansi: :red] }
    end

    describe 'with s3 config missing' do
      let(:gsc_options)  { nil }
      it { should include_sexp [:echo, 'Worker GCS config missing: bucket name, access key id, secret access key', ansi: :red] }
    end
  end

  describe 'install' do
    before { cache.install }

    let(:url) { "https://raw.githubusercontent.com/travis-ci/casher/#{branch}/bin/casher" }
    let(:cmd) { [:cmd,  "curl #{url}  -L -o $CASHER_DIR/bin/casher -s --fail", retry: true, display: 'Installing caching utilities'] }

    describe 'uses casher production in default mode' do
      let(:branch) { 'production' }
      it { should include_sexp [:export, ['CASHER_DIR', '$HOME/.casher'], echo: true] }
      it { should include_sexp [:mkdir, '$CASHER_DIR/bin', recursive: true] }
      it { should include_sexp :cmd }
      it { should include_sexp [:raw, '[ $? -ne 0 ] && echo \'Failed to fetch casher from GitHub, disabling cache.\' && echo > $CASHER_DIR/bin/casher'] }
    end

    describe 'uses casher master in edge mode' do
      let(:branch) { 'master' }
      let(:config) { { cache: { edge: true } } }
      it { should include_sexp :cmd }
    end

    describe 'passing a casher branch' do
      let(:branch) { 'foo' }
      let(:config) { { cache: { branch: branch } } }
      it { should include_sexp :cmd }
    end

    describe 'using debug flag' do
      let(:config) { { cache: { debug: true } } }
      let(:cmd) { [:cmd,  "curl #{url} -v #{described_class::CURL_FORMAT} -L -o $CASHER_DIR/bin/casher -s --fail", retry: true, display: 'Installing caching utilities'] }
      it { should include_sexp :cmd }
    end
  end

  describe 'fetch' do
    before { cache.fetch }
    it { should include_sexp [:cmd, "rvm 1.9.3 --fuzzy do $CASHER_DIR/bin/casher fetch #{fetch_url_tgz} #{fetch_url}", timing: true] }
  end

  describe 'add' do
    before { cache.add('/foo/bar') }
    it { should include_sexp [:cmd, 'rvm 1.9.3 --fuzzy do $CASHER_DIR/bin/casher add /foo/bar'] }

    context 'when multiple directories are given' do
      before { cache.setup_casher }
      let(:config) { { cache: { directories: ['/foo/bar', '/bar/baz'] } } }

      it { should include_sexp [:cmd, 'rvm 1.9.3 --fuzzy do $CASHER_DIR/bin/casher add /foo/bar /bar/baz'] }
    end

    context 'when more than ADD_DIR_MAX directories are given' do
      before { cache.setup_casher }
      let(:dirs) { ('dir000'...'dir999').to_a }
      let(:config) { { cache: { directories: dirs } } }

      it { should include_sexp [:cmd, "rvm 1.9.3 --fuzzy do $CASHER_DIR/bin/casher add #{dirs.take(Travis::Build::Script::DirectoryCache::S3::ADD_DIR_MAX).join(' ')}"] }
    end
  end

  describe 'push' do
    before { cache.push }
    it { should include_sexp [:cmd, "rvm 1.9.3 --fuzzy do $CASHER_DIR/bin/casher push #{push_url}", timing: true] }
  end

  describe 'on a different branch' do
    let(:branch)          { 'featurefoo' }
    let(:fetch_signature) { 'cbce59b97e29ba90e1810a9cbedc1d5cd76df8235064c0016a53dea232124d60' }
    let(:fetch_signature_tgz) { 'f0842c7f68c3b518502a336c5e55cfa368c90f72a06e2b58889cfd844380310b' }
    let(:push_signature)  { '3642ae12b63114366d42c964e221b7e9dcf736286a6fde1fd93be3fa21acb324' }
    let(:fallback_url)    { signed_url_for('master', master_fetch_signature) }
    let(:fallback_url_tgz)    { signed_url_for('master', master_fetch_signature_tgz, 'tgz') }

    describe 'fetch' do
      before { cache.fetch }
      it { should include_sexp [:cmd, "rvm 1.9.3 --fuzzy do $CASHER_DIR/bin/casher fetch #{fetch_url_tgz} #{fetch_url} #{fallback_url_tgz} #{fallback_url}", timing: true] }
    end

    describe 'add' do
      before { cache.add('/foo/bar') }
      it { should include_sexp [:cmd, 'rvm 1.9.3 --fuzzy do $CASHER_DIR/bin/casher add /foo/bar'] }
    end

    describe 'push' do
      before { cache.push }
      it { should include_sexp [:cmd, "rvm 1.9.3 --fuzzy do $CASHER_DIR/bin/casher push #{push_url}", timing: true] }
    end
  end

  describe 'on a pull request' do
    let(:pull_request)    { 15 }
    let(:fetch_signature) { 'b1db673b9a243ecbc792fd476c4f5b45462449dd73b65987d11710b42f180773' }
    let(:fetch_signature_tgz) { 'b17be191a6770e15e3b8c598843cd1503a674aab4f8853d303e2d6d694fa1fd6' }
    let(:push_signature)  { '4aa0c287dca37b5c7f9d14e84be0680c4151c8230b2d0c6e8299d031d4bebd29' }
    let(:url)             { url_for("PR.#{pull_request}") }
    let(:url_tgz)         { url_for("PR.#{pull_request}", 'tgz') }
    let(:fallback_url)    { signed_url_for('master', master_fetch_signature) }
    let(:fallback_url_tgz)    { signed_url_for('master', master_fetch_signature_tgz, 'tgz') }

    describe 'fetch' do
      before { cache.fetch }
      it { should include_sexp [:cmd, "rvm 1.9.3 --fuzzy do $CASHER_DIR/bin/casher fetch #{fetch_url_tgz} #{fetch_url} #{fallback_url_tgz} #{fallback_url}", timing: true] }
    end

    describe 'add' do
      before { cache.add('/foo/bar') }
      it { should include_sexp [:cmd, 'rvm 1.9.3 --fuzzy do $CASHER_DIR/bin/casher add /foo/bar'] }
    end

    describe 'push' do
      before { cache.push }
      it { should include_sexp [:cmd, "rvm 1.9.3 --fuzzy do $CASHER_DIR/bin/casher push #{push_url}", timing: true] }
    end
  end

  describe 'on a pull request to a different branch' do
    let(:pull_request)    { 15 }
    let(:branch)          { 'foo' }
    let(:fetch_signature) { 'b1db673b9a243ecbc792fd476c4f5b45462449dd73b65987d11710b42f180773' }
    let(:fetch_signature_tgz) { 'b17be191a6770e15e3b8c598843cd1503a674aab4f8853d303e2d6d694fa1fd6' }
    let(:push_signature)  { '4aa0c287dca37b5c7f9d14e84be0680c4151c8230b2d0c6e8299d031d4bebd29' }
    let(:url)             { url_for("PR.#{pull_request}") }
    let(:url_tgz)         { url_for("PR.#{pull_request}", 'tgz') }
    let(:fallback_url)    { signed_url_for('master', master_fetch_signature) }
    let(:fallback_url_tgz)    { signed_url_for('master', master_fetch_signature_tgz, 'tgz') }
    let(:branch_fallback_url) { signed_url_for('foo', 'd72269ea040415d06cea7382c25f211f05b5a701c68299c03bbecd861a5e820b') }
    let(:branch_fallback_url_tgz) { signed_url_for('foo', 'e25b5a05709b557e35140cba079b597faae02da0733d7c18e848ce91140a5331', 'tgz') }

    describe 'fetch' do
      before { cache.fetch }
      it { should include_sexp [:cmd, "rvm 1.9.3 --fuzzy do $CASHER_DIR/bin/casher fetch #{fetch_url_tgz} #{fetch_url} #{branch_fallback_url_tgz} #{branch_fallback_url} #{fallback_url_tgz} #{fallback_url}", timing: true] }
    end

    describe 'add' do
      before { cache.add('/foo/bar') }
      it { should include_sexp [:cmd, 'rvm 1.9.3 --fuzzy do $CASHER_DIR/bin/casher add /foo/bar'] }
    end

    describe 'push' do
      before { cache.push }
      it { should include_sexp [:cmd, "rvm 1.9.3 --fuzzy do $CASHER_DIR/bin/casher push #{push_url}", timing: true] }
    end
  end

  describe '#signature' do
    it "works with Amazon's example" do
      host_proc = lambda {|region| region == 'us-east-1' ? 's3.amazonaws.com' : "s3-#{region}.amazonaws.com" }

      key_pair = described_class::KeyPair.new('AKIAIOSFODNN7EXAMPLE', 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY')
      location = described_class::Location.new('https', 'us-east-1', 'johnsmith', '/photos/puppy.jpg', host_proc)
      signature = Travis::Build::Script::DirectoryCache::Signatures::AWS2Signature.new(key_pair, 'GET', location, 86400, Time.gm(2007, 3, 27, 19, 36, 42))

      expect(signature.sign).to eq('bWq2s1WEIj+Ydj0vQ697zp+IXMU=')
    end
  end
end
