require 'spec_helper'

describe Travis::Build::Script::DirectoryCache::Gcs, :sexp do
  GCS_FETCH_URL  = "https://s3_bucket.storage.googleapis.com/42/%s/example.%s?Expires=%s"
  GCS_SIGNED_URL = "%s&GoogleAccessId=google_access_key_id&Signature=%s"

  def url_for(branch, ext = 'tbz', timeout = 30)
    GCS_FETCH_URL % [ branch, ext, timeout ]
  end

  def signed_url_for(branch, signature, ext = 'tbz', timeout = 30)
    Shellwords.escape(GCS_SIGNED_URL % [url_for(URI.encode(branch), ext, timeout), signature])
  end

  let(:master_fetch_signature) { "rtH5pKA2GoRqKYjQu3UweW5kRSk%3D" }
  let(:master_fetch_signature_tgz) { "YK5xuBkUv6FLo5jRerYcx4QYB4I%3D" }
  let(:fetch_signature)        { master_fetch_signature }
  let(:fetch_signature_tgz)    { master_fetch_signature_tgz }
  let(:push_signature)         { "NKjp5aeeVJXqJI6FovroSWDsg4w%3D" }

  let(:test_time)     { 10 }
  let(:timeout)       { cache_options[:push_timeout] + test_time }
  let(:url_tgz)       { signed_url_for(branch, fetch_signature_tgz, 'tgz') }
  let(:fetch_url_tgz) { url_tgz }
  let(:push_url)      { signed_url_for(branch, push_signature, 'tgz', timeout) }

  let(:gcs_options)   { { bucket: 's3_bucket', secret_access_key: 'google_secret_access_key', access_key_id: 'google_access_key_id', aws_signature_version: '2' } }
  let(:cache_options) { { fetch_timeout: 20, push_timeout: 30, type: 'gcs', gcs: gcs_options } }
  let(:data)          { PAYLOADS[:push].deep_merge(paranoid: disable_sudo, config: config, cache_options: cache_options, job: { branch: branch, pull_request: pull_request }) }
  let(:config)        { {} }
  let(:disable_sudo)  { false }
  let(:pull_request)  { nil }
  let(:branch)        { 'master' }
  let(:sh)            { Travis::Shell::Builder.new }
  let(:cache)         { described_class.new(sh, Travis::Build::Data.new(data), 'example', test_time) }
  let(:subject)       { sh.to_sexp }

  let(:key_pair) { described_class::KeyPair.new(gcs_options[:access_key_id], [:secret_access_key]) }

  before do
    # Assume time is at Epoch, which is expected by the V2 signature's Expires header
    Time.stubs(:now).returns 0
    # Set an app_host so casher messages are right
    Travis::Build.config.app_host = 'build.travis-ci.org'
  end

  describe 'validate' do
    before { cache.valid? }

    describe 'with valid s3' do
      it { should_not include_sexp [:echo, 'Worker GCS config missing: bucket name, access key id, secret access key', ansi: :red] }
    end

    describe 'with s3 config missing' do
      let(:gcs_options)  { nil }
      it { should include_sexp [:echo, 'Worker GCS config missing: bucket name, access key id, secret access key', ansi: :red] }
    end
  end

  describe 'install' do
    before { cache.install }

    let(:url) { "https://raw.githubusercontent.com/travis-ci/casher/#{branch}/bin/casher" }
    let(:cmd) { [:cmd,  "curl -sf  -o $CASHER_DIR/bin/casher #{url}", retry: true, echo: 'Installing caching utilities'] }

    describe 'uses casher bash in default mode' do
      let(:branch) { 'bash' }
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
    let(:timeout) { cache_options[:fetch_timeout] }
    before { cache.fetch }
    it { should include_sexp [:cmd, "rvm $(travis_internal_ruby) --fuzzy do $CASHER_DIR/bin/casher --name example cache fetch #{url_tgz}", timing: true] }
  end

  describe 'add' do
    before { cache.add('/foo/bar') }
    it { should include_sexp [:cmd, 'rvm $(travis_internal_ruby) --fuzzy do $CASHER_DIR/bin/casher --name example cache add /foo/bar'] }

    context 'when multiple directories are given' do
      before { cache.setup_casher }
      let(:config) { { cache: { directories: ['/foo/bar', '/bar/baz'] } } }

      it { should include_sexp [:cmd, 'rvm $(travis_internal_ruby) --fuzzy do $CASHER_DIR/bin/casher --name example cache add /foo/bar /bar/baz'] }
    end

    context 'when more than ADD_DIR_MAX directories are given' do
      before { cache.setup_casher }
      let(:dirs) { ('dir000'...'dir999').to_a }
      let(:config) { { cache: { directories: dirs } } }

      it { should include_sexp [:cmd, "rvm $(travis_internal_ruby) --fuzzy do $CASHER_DIR/bin/casher --name example cache add #{dirs.take(Travis::Build::Script::DirectoryCache::S3::ADD_DIR_MAX).join(' ')}"] }
    end
  end

  describe 'push' do
    let(:timeout) { cache_options[:push_timeout] + test_time }
    before { cache.push }
    it { should include_sexp [:cmd, "rvm $(travis_internal_ruby) --fuzzy do $CASHER_DIR/bin/casher --name example cache push #{push_url}", timing: true] }
  end

  describe 'on a different branch' do
    let(:branch)          { 'featurefoo' }
    let(:fetch_signature) { 'RCp7Cd2IKLRCvEC%2F1sZRVBUBKx8%3D' }
    let(:fetch_signature_tgz) { 'GWX9Uh4HiQ9UDasvRB9pqRoq%2FI4%3D' }
    let(:push_signature)  { 'PHCIJ5h7qNkwVF9FceW%2F52ds%2Fw0%3D' }
    let(:fallback_url_tgz)    { signed_url_for('master', master_fetch_signature_tgz, 'tgz') }

    describe 'fetch' do
      before { cache.fetch }
      it { should include_sexp [:cmd, "rvm $(travis_internal_ruby) --fuzzy do $CASHER_DIR/bin/casher --name example cache fetch #{fetch_url_tgz} #{fallback_url_tgz}", timing: true] }
    end

    describe 'add' do
      before { cache.add('/foo/bar') }
      it { should include_sexp [:cmd, 'rvm $(travis_internal_ruby) --fuzzy do $CASHER_DIR/bin/casher --name example cache add /foo/bar'] }
    end

    describe 'push' do
      before { cache.push }
      it { should include_sexp [:cmd, "rvm $(travis_internal_ruby) --fuzzy do $CASHER_DIR/bin/casher --name example cache push #{push_url}", timing: true] }
    end
  end

  describe 'on a branch with emoji' do
    let(:branch)          { '🐡' }
    let(:fetch_signature_tgz) { 'nw6VstugEoKi6SOErSiSaRCcrE0%3D' }
    let(:push_signature)  { 'eftInSKO6b3Z4qRWdqzuD%2FIdPbw%3D' }
    let(:fallback_url_tgz)    { signed_url_for('master', master_fetch_signature_tgz, 'tgz') }

    describe 'fetch' do
      before { cache.fetch }
      it { should include_sexp [:cmd, "rvm $(travis_internal_ruby) --fuzzy do $CASHER_DIR/bin/casher --name example cache fetch #{fetch_url_tgz} #{fallback_url_tgz}", timing: true] }
    end

    describe 'add' do
      before { cache.add('/foo/bar') }
      it { should include_sexp [:cmd, 'rvm $(travis_internal_ruby) --fuzzy do $CASHER_DIR/bin/casher --name example cache add /foo/bar'] }
    end

    describe 'push' do
      before { cache.push }
      it { should include_sexp [:cmd, "rvm $(travis_internal_ruby) --fuzzy do $CASHER_DIR/bin/casher --name example cache push #{push_url}", timing: true] }
    end
  end

  describe 'on a pull request' do
    let(:pull_request)    { 15 }
    let(:fetch_signature) { '4xhck0G2%2BSCjz%2BGFkpEA1pj27I8%3D' }
    let(:fetch_signature_tgz) { 'N0qlG8k9ihBVE9uGemKdvVVuHLA%3D' }
    let(:push_signature)  { 'gF%2Ba%2Fu559%2B97Sxy3UzGBgjThAgo%3D' }
    let(:url_tgz)         { signed_url_for("PR.#{pull_request}", fetch_signature_tgz, 'tgz') }
    let(:push_url)        { signed_url_for("PR.#{pull_request}", push_signature, 'tgz', timeout) }
    let(:fallback_url_tgz)    { signed_url_for('master', master_fetch_signature_tgz, 'tgz') }

    describe 'fetch' do
      before { cache.fetch }
      it { should include_sexp [:cmd, "rvm $(travis_internal_ruby) --fuzzy do $CASHER_DIR/bin/casher --name example cache fetch #{fetch_url_tgz} #{fallback_url_tgz}", timing: true] }
    end

    describe 'add' do
      before { cache.add('/foo/bar') }
      it { should include_sexp [:cmd, 'rvm $(travis_internal_ruby) --fuzzy do $CASHER_DIR/bin/casher --name example cache add /foo/bar'] }
    end

    describe 'push' do
      before { cache.push }
      it { should include_sexp [:cmd, "rvm $(travis_internal_ruby) --fuzzy do $CASHER_DIR/bin/casher --name example cache push #{push_url}", timing: true] }
    end
  end

  describe 'on a pull request to a different branch' do
    let(:pull_request)    { 15 }
    let(:branch)          { 'foo' }
    let(:fetch_signature) { '4xhck0G2%2BSCjz%2BGFkpEA1pj27I8%3D' }
    let(:fetch_signature_tgz) { 'N0qlG8k9ihBVE9uGemKdvVVuHLA%3D' }
    let(:push_signature)  { 'gF%2Ba%2Fu559%2B97Sxy3UzGBgjThAgo%3D' }
    let(:url_tgz)         { signed_url_for("PR.#{pull_request}", fetch_signature_tgz, 'tgz') }
    let(:push_url)        { signed_url_for("PR.#{pull_request}", push_signature, 'tgz', timeout) }
    let(:fallback_url_tgz)    { signed_url_for('master', master_fetch_signature_tgz, 'tgz') }
    let(:branch_fallback_url_tgz) { signed_url_for('foo', 'aEutjpVj13QxPYd7VRO%2BDdhr3cg%3D', 'tgz') }

    describe 'fetch' do
      before { cache.fetch }
      it { should include_sexp [:cmd, "rvm $(travis_internal_ruby) --fuzzy do $CASHER_DIR/bin/casher --name example cache fetch #{fetch_url_tgz} #{branch_fallback_url_tgz} #{fallback_url_tgz}", timing: true] }
    end

    describe 'add' do
      before { cache.add('/foo/bar') }
      it { should include_sexp [:cmd, 'rvm $(travis_internal_ruby) --fuzzy do $CASHER_DIR/bin/casher --name example cache add /foo/bar'] }
    end

    describe 'push' do
      before { cache.push }
      it { should include_sexp [:cmd, "rvm $(travis_internal_ruby) --fuzzy do $CASHER_DIR/bin/casher --name example cache push #{push_url}", timing: true] }
    end
  end

  describe '#signature' do
    it "works with Amazon's example" do
      # See http://docs.aws.amazon.com/AmazonS3/latest/dev/RESTAuthentication.html#RESTAuthenticationQueryStringAuth
      key_pair = described_class::KeyPair.new('AKIAIOSFODNN7EXAMPLE', 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY')
      location = described_class::Location.new('https', 'us-east-1', 'johnsmith', '/photos/puppy.jpg')
      signature = Travis::Build::Script::DirectoryCache::Signatures::AWS2Signature.new(key: key_pair, http_verb: 'GET', location: location, expires: 1175139620, timestamp: Time.gm(2007, 3, 26, 19, 37, 58))

      expect(signature.sign).to eq('NpgCjnDzrM+WFzoENXmpNDUsSn8=')
    end
  end
end
