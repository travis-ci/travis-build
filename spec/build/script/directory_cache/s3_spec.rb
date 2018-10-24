require 'spec_helper'

describe Travis::Build::Script::DirectoryCache::S3, :sexp do
  S3_FETCH_URL  = "https://s3.amazonaws.com/s3_bucket/42/%s/example.%s?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=s3_access_key_id%%2F19700101%%2Fus-east-1%%2Fs3%%2Faws4_request&X-Amz-Date=19700101T000010Z"
  S3_SIGNED_URL = "%s&X-Amz-Expires=20&X-Amz-Signature=%s&X-Amz-SignedHeaders=host"

  def url_for(branch, ext = 'tbz')
    S3_FETCH_URL % [ branch, ext ]
  end

  def signed_url_for(branch, signature, ext = 'tbz')
    Shellwords.escape(S3_SIGNED_URL % [url_for(URI.encode(branch), ext), signature])
  end

  let(:master_fetch_signature) { "163b2a236fcfda37d58c1d50c27d86fbd04efb4a6d97219134f71854e3e0383b" }
  let(:master_fetch_signature_tgz) { "b6282b850382aacaf1ce425ca3ed7add79e9ab82bca3099e13e312919fdfd8da" }
  let(:fetch_signature)        { master_fetch_signature }
  let(:fetch_signature_tgz)    { master_fetch_signature_tgz }
  let(:push_signature)         { "d388be7ca53fb612892cffe0844c957ee6062efe08c997ddcb5d2e8e1501e339" }

  let(:url)           { url_for(URI.encode(branch)) }
  let(:url_tgz)       { url_for(URI.encode(branch), 'tgz') }
  let(:fetch_url_tgz) { Shellwords.escape "#{url_tgz}&X-Amz-Expires=20&X-Amz-Signature=#{fetch_signature_tgz}&X-Amz-SignedHeaders=host" }
  let(:push_url)      { Shellwords.escape("#{url}&X-Amz-Expires=30&X-Amz-Signature=#{push_signature}&X-Amz-SignedHeaders=host").gsub(/\.tbz(\?)?/, '.tgz\1') }

  let(:s3_options)    { { bucket: 's3_bucket', secret_access_key: 's3_secret_access_key', access_key_id: 's3_access_key_id' } }
  let(:cache_options) { { fetch_timeout: 20, push_timeout: 30, type: 's3', s3: s3_options } }
  let(:data)          { PAYLOADS[:push].deep_merge(paranoid: disable_sudo, config: config, cache_options: cache_options, job: { branch: branch, pull_request: pull_request }) }
  let(:config)        { {} }
  let(:disable_sudo)  { false }
  let(:pull_request)  { nil }
  let(:branch)        { 'master' }
  let(:sh)            { Travis::Shell::Builder.new }
  let(:cache)         { described_class.new(sh, Travis::Build::Data.new(data), 'example', Time.at(10)) }
  let(:subject)       { sh.to_sexp }

  before do
    # Set an app_host so casher messages are right
    Travis::Build.config.app_host = 'build.travis-ci.org'
  end

  describe 'validate' do
    before { cache.valid? }

    describe 'with valid s3' do
      it { should_not include_sexp [:echo, 'Worker S3 config missing: bucket name, access key id, secret access key', ansi: :red] }
    end

    describe 'with s3 config missing' do
      let(:s3_options)  { nil }
      it { should include_sexp [:echo, 'Worker S3 config missing: bucket name, access key id, secret access key', ansi: :red] }
    end
  end

  describe 'install' do
    before { cache.install }

    let(:url) { "https://raw.githubusercontent.com/travis-ci/casher/#{branch}/bin/casher" }
    let(:cmd) { [:cmd,  "curl -sf  -o $CASHER_DIR/bin/casher #{url}", retry: true, echo: 'Installing caching utilities'] }

    describe 'uses casher production in default mode' do
      let(:branch) { 'production' }
      let(:cmd) { [:cmd,  "curl -sf  -o $CASHER_DIR/bin/casher #{url}",retry: true, echo: "Installing caching utilities from the Travis CI server (https://#{Travis::Build.config.app_host.output_safe}/files/casher) failed, failing over to using GitHub (#{url})"] }
      it { should include_sexp [:export, ['CASHER_DIR', '${TRAVIS_HOME}/.casher'], echo: true] }
      it { should include_sexp [:mkdir, '$CASHER_DIR/bin', recursive: true] }
      it { should include_sexp cmd }
      it { should include_sexp [:echo, 'Failed to fetch casher from GitHub, disabling cache.', ansi: :yellow] }
    end

    describe 'uses casher master in edge mode' do
      let(:branch) { 'master' }
      let(:config) { { cache: { edge: true } } }
      it { should include_sexp cmd }
    end

    describe 'passing a casher branch' do
      let(:branch) { 'foo' }
      let(:config) { { cache: { branch: branch } } }
      it { should include_sexp cmd }
    end

    describe 'using debug flag' do
      let(:config) { { cache: { debug: true, branch: branch } } }
      let(:cmd) { [:cmd,  "curl -sf -v -w '#{described_class::CURL_FORMAT}' -o $CASHER_DIR/bin/casher #{url}", retry: true, echo: 'Installing caching utilities'] }
      it { should include_sexp cmd }
    end
  end

  describe 'fetch' do
    before { cache.fetch }
    it { should include_sexp [:cmd, "rvm $(travis_internal_ruby) --fuzzy do $CASHER_DIR/bin/casher fetch #{fetch_url_tgz}", timing: true] }
  end

  describe 'add' do
    before { cache.add('/foo/bar') }
    it { should include_sexp [:cmd, 'rvm $(travis_internal_ruby) --fuzzy do $CASHER_DIR/bin/casher add /foo/bar'] }

    context 'when multiple directories are given' do
      before { cache.setup_casher }
      let(:config) { { cache: { directories: ['/foo/bar', '/bar/baz'] } } }

      it { should include_sexp [:cmd, 'rvm $(travis_internal_ruby) --fuzzy do $CASHER_DIR/bin/casher add /foo/bar /bar/baz'] }
    end

    context 'when more than ADD_DIR_MAX directories are given' do
      before { cache.setup_casher }
      let(:dirs) { ('dir000'...'dir999').to_a }
      let(:config) { { cache: { directories: dirs } } }

      it { should include_sexp [:cmd, "rvm $(travis_internal_ruby) --fuzzy do $CASHER_DIR/bin/casher add #{dirs.take(Travis::Build::Script::DirectoryCache::S3::ADD_DIR_MAX).join(' ')}"] }
    end
  end

  describe 'push' do
    before { cache.push }
    it { should include_sexp [:cmd, "rvm $(travis_internal_ruby) --fuzzy do $CASHER_DIR/bin/casher push #{push_url}", timing: true] }
  end

  describe 'on a different branch' do
    let(:branch)          { 'featurefoo' }
    let(:fetch_signature) { 'cbce59b97e29ba90e1810a9cbedc1d5cd76df8235064c0016a53dea232124d60' }
    let(:fetch_signature_tgz) { 'a8b6b4380bd25cd9f402ff3fa896d6cbad6a1f9cdf21a6bcb0b956d04b49f2a5' }
    let(:push_signature)  { 'ced8bb92b9cf7a2005aacbe9158d239c8500976277faf17ce46597b2d17a8f0c' }
    let(:fallback_url_tgz)    { signed_url_for('master', master_fetch_signature_tgz, 'tgz') }

    describe 'fetch' do
      before { cache.fetch }
      it { should include_sexp [:cmd, "rvm $(travis_internal_ruby) --fuzzy do $CASHER_DIR/bin/casher fetch #{fetch_url_tgz} #{fallback_url_tgz}", timing: true] }
    end

    describe 'add' do
      before { cache.add('/foo/bar') }
      it { should include_sexp [:cmd, 'rvm $(travis_internal_ruby) --fuzzy do $CASHER_DIR/bin/casher add /foo/bar'] }
    end

    describe 'push' do
      before { cache.push }
      it { should include_sexp [:cmd, "rvm $(travis_internal_ruby) --fuzzy do $CASHER_DIR/bin/casher push #{push_url}", timing: true] }
    end
  end

  describe 'on a branch with emoji' do
    let(:branch)          { '🐡' }
    let(:fetch_signature_tgz) { '5b45e7c91892daf27e4b87da42f4f6fce034f81c3f8231649121d4d130a755b9' }
    let(:push_signature)  { 'a09d1d7f25999ec24b6c5e7ec7472a81a57bbb35f84c0a2caa507e3b20b9f4ba' }
    let(:fallback_url_tgz)    { signed_url_for('master', master_fetch_signature_tgz, 'tgz') }

    describe 'fetch' do
      before { cache.fetch }
      it { should include_sexp [:cmd, "rvm $(travis_internal_ruby) --fuzzy do $CASHER_DIR/bin/casher fetch #{fetch_url_tgz} #{fallback_url_tgz}", timing: true] }
    end

    describe 'add' do
      before { cache.add('/foo/bar') }
      it { should include_sexp [:cmd, 'rvm $(travis_internal_ruby) --fuzzy do $CASHER_DIR/bin/casher add /foo/bar'] }
    end

    describe 'push' do
      before { cache.push }
      it { should include_sexp [:cmd, "rvm $(travis_internal_ruby) --fuzzy do $CASHER_DIR/bin/casher push #{push_url}", timing: true] }
    end
  end

  describe 'on a pull request' do
    let(:pull_request)    { 15 }
    let(:fetch_signature) { 'b1db673b9a243ecbc792fd476c4f5b45462449dd73b65987d11710b42f180773' }
    let(:fetch_signature_tgz) { '2641b71927a0e494f925ef3afacbd7083bc4f307a0acc693f8ff3f6d67ea179f' }
    let(:push_signature)  { '107f513b12c8f93f3a6e08b51ae8efe20f69bc7635f4c488f09bb06f14437cac' }
    let(:url)             { url_for("PR.#{pull_request}") }
    let(:url_tgz)         { url_for("PR.#{pull_request}", 'tgz') }
    let(:fallback_url_tgz)    { signed_url_for('master', master_fetch_signature_tgz, 'tgz') }

    describe 'fetch' do
      before { cache.fetch }
      it { should include_sexp [:cmd, "rvm $(travis_internal_ruby) --fuzzy do $CASHER_DIR/bin/casher fetch #{fetch_url_tgz} #{fallback_url_tgz}", timing: true] }
    end

    describe 'add' do
      before { cache.add('/foo/bar') }
      it { should include_sexp [:cmd, 'rvm $(travis_internal_ruby) --fuzzy do $CASHER_DIR/bin/casher add /foo/bar'] }
    end

    describe 'push' do
      before { cache.push }
      it { should include_sexp [:cmd, "rvm $(travis_internal_ruby) --fuzzy do $CASHER_DIR/bin/casher push #{push_url}", timing: true] }
    end
  end

  describe 'on a pull request to a different branch' do
    let(:pull_request)    { 15 }
    let(:branch)          { 'foo' }
    let(:fetch_signature) { 'b1db673b9a243ecbc792fd476c4f5b45462449dd73b65987d11710b42f180773' }
    let(:fetch_signature_tgz) { '2641b71927a0e494f925ef3afacbd7083bc4f307a0acc693f8ff3f6d67ea179f' }
    let(:push_signature)  { '107f513b12c8f93f3a6e08b51ae8efe20f69bc7635f4c488f09bb06f14437cac' }
    let(:url)             { url_for("PR.#{pull_request}") }
    let(:url_tgz)         { url_for("PR.#{pull_request}", 'tgz') }
    let(:fallback_url_tgz)    { signed_url_for('master', master_fetch_signature_tgz, 'tgz') }
    let(:branch_fallback_url_tgz) { signed_url_for('foo', '5b2cabde3b2a67563a8e26ded3a000ba8a0bc5c30faa102588d44036d444ec67', 'tgz') }

    describe 'fetch' do
      before { cache.fetch }
      it { should include_sexp [:cmd, "rvm $(travis_internal_ruby) --fuzzy do $CASHER_DIR/bin/casher fetch #{fetch_url_tgz} #{branch_fallback_url_tgz} #{fallback_url_tgz}", timing: true] }
    end

    describe 'add' do
      before { cache.add('/foo/bar') }
      it { should include_sexp [:cmd, 'rvm $(travis_internal_ruby) --fuzzy do $CASHER_DIR/bin/casher add /foo/bar'] }
    end

    describe 'push' do
      before { cache.push }
      it { should include_sexp [:cmd, "rvm $(travis_internal_ruby) --fuzzy do $CASHER_DIR/bin/casher push #{push_url}", timing: true] }
    end
  end

  describe 'signatures' do
    it "works with Amazon's example" do
      key_pair = described_class::KeyPair.new('AKIAIOSFODNN7EXAMPLE', 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY')
      location = described_class::Location.new('https', 'us-east-1', 'examplebucket', '/test.txt', 's3.amazonaws.com')
      signature = Travis::Build::Script::DirectoryCache::Signatures::AWS4Signature.new(key: key_pair, http_verb: 'GET', location: location, expires: 86400, timestamp: Time.gm(2013, 5, 24))

      # note that the computed signature is different from the value shown in http://docs.aws.amazon.com/AmazonS3/latest/API/sigv4-query-string-auth.html
      expect(signature.to_uri.query_values['X-Amz-Signature']).to eq('53fc89bc4880655f485ba948c2b85d096741144d6cd6b314763f84850b5c20fa')
    end
  end
end
