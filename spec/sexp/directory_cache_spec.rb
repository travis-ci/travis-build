require 'spec_helper'

describe Travis::Build::Script::DirectoryCache do
  let(:sh)      { Travis::Shell::Builder.new }
  let(:options) { { fetch_timeout: 20, push_timeout: 30, type: 's3', s3: { bucket: 's3_bucket', secret_access_key: 's3_secret_access_key', access_key_id: 's3_access_key_id' } } }

  # sh.export 'CASHER_DIR', '$HOME/.casher'

  # sh.mkdir '$CASHER_DIR/bin', echo: false, recursive: true
  # sh.cmd "curl #{CASHER_URL % @casher_branch} -L -o #{BIN_PATH} -s --fail", retry: true
  # sh.cmd "[ $? -ne 0 ] && echo 'Failed to fetch casher from GitHub, disabling cache.' && echo > #{BIN_PATH}"

  # sh.if "-f #{BIN_PATH}" do
  #   sh.chmod '+x', BIN_PATH
  # end

  describe 'dummy caching' do
    let(:data)   { Travis::Build::Data.new(config: { cache: config }, cache_options: options) }
    let(:script) { Struct.new(:sh, :data) { include(Travis::Build::Script::DirectoryCache) }.new(sh, data) }
    subject      { script }

    describe 'with no caching enabled' do
      let(:config) { {} }

      it { should_not be_use_directory_cache }

      describe '#cache_class' do
        subject { script.cache_class }
        it { should eq(Travis::Build::Script::DirectoryCache::Dummy) }
      end
    end

    describe 'with caching enabled' do
      let(:config) { { directories: ['foo'] } }
      it { should be_use_directory_cache }

      describe '#cache_class' do
        subject { script.cache_class }
        it { should eq(Travis::Build::Script::DirectoryCache::S3) }
      end
    end

    describe 'casher branch' do
      describe 'normal mode' do
        let(:config) { {} }

        describe '#casher_branch' do
          subject { script.casher_branch }
          it { should eq('production') }
        end
      end

      describe 'edge mode' do
        let(:config) { { edge: true } }

        describe '#casher_branch' do
          subject { script.casher_branch }
          it { should eq('master') }
        end
      end
    end
  end

  describe Travis::Build::Script::DirectoryCache::S3, :sexp do
    describe 'signatures' do
      it "works with Amazon's example" do
        key_pair = described_class::KeyPair.new('AKIAIOSFODNN7EXAMPLE', 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY')
        location = described_class::Location.new('https', 'us-east-1', 'examplebucket', '/test.txt')
        signature = described_class::AWS4Signature.new(key_pair, 'GET', location, 86400, Time.gm(2013, 5, 24))

        expect(signature.to_uri.query_values['X-Amz-Signature']).to eq('aeeed9bbccd4d02ee5c0109b86d86835f995330da4c265957d157751f604d404')
      end
    end

    def url_for(branch)
      pattern = "https://s3_bucket.s3.amazonaws.com/42/%s/example.tbz?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=s3_access_key_id%%2F19700101%%2Fus-east-1%%2Fs3%%2Faws4_request&X-Amz-Date=19700101T000010Z"
      pattern % branch
    end

    let(:global_fallback)        { "https://s3_bucket.s3.amazonaws.com/42/example.tbz\\?X-Amz-Algorithm\\=AWS4-HMAC-SHA256\\&X-Amz-Credential\\=s3_access_key_id\\%2F19700101\\%2Fus-east-1\\%2Fs3\\%2Faws4_request\\&X-Amz-Date\\=19700101T000010Z\\&X-Amz-Expires\\=20\\&X-Amz-Signature\\=7f206e62deecd81668ca0093f051aeeaaff5c7f53dcf74186c468e4eef3c1e75\\&X-Amz-SignedHeaders\\=host" }
    let(:master_fetch_signature) { "163b2a236fcfda37d58c1d50c27d86fbd04efb4a6d97219134f71854e3e0383b" }
    let(:fetch_signature)        { master_fetch_signature }
    let(:push_signature)         { "926885a758f00d51eaad281522a26cf7151fdd530aa1272c1d8c607c2e778570" }

    let(:url)             { url_for(branch) }
    let(:fetch_url)       { Shellwords.escape "#{url}&X-Amz-Expires=20&X-Amz-Signature=#{fetch_signature}&X-Amz-SignedHeaders=host" }
    let(:push_url)        { Shellwords.escape "#{url}&X-Amz-Expires=30&X-Amz-Signature=#{push_signature}&X-Amz-SignedHeaders=host" }
    let(:data)            { PAYLOADS[:push].deep_merge(cache_options: options, job: { branch: branch }) }
    let(:branch)          { 'master' }

    let(:directory_cache) { described_class.new(Travis::Build::Data.new(data), 'ex a/mple', 'production', Time.at(10)) }
    let(:subject)         { sh.to_sexp }

    describe 'install' do
      before { directory_cache.install(sh) }

      it { should include_sexp [:export, ['CASHER_DIR', '$HOME/.casher'], echo: true] }
      it { should include_sexp [:mkdir, '$CASHER_DIR/bin', recursive: true] }
      it { should include_sexp [:cmd,  'curl https://raw.githubusercontent.com/travis-ci/casher/production/bin/casher -L -o $CASHER_DIR/bin/casher -s --fail', retry: true] }
      it { should include_sexp [:cmd, '[ $? -ne 0 ] && echo \'Failed to fetch casher from GitHub, disabling cache.\' && echo > $CASHER_DIR/bin/casher'] }
    end

    describe 'fetch' do
      before { directory_cache.fetch(sh) }
      it { should include_sexp [:cmd, "rvm 1.9.3 --fuzzy do $CASHER_DIR/bin/casher fetch #{fetch_url} #{global_fallback}"] }
    end

    describe 'add' do
      before { directory_cache.add(sh, '/foo/bar') }
      it { should include_sexp [:cmd, 'rvm 1.9.3 --fuzzy do $CASHER_DIR/bin/casher add /foo/bar'] }
    end

    describe 'push' do
      before { directory_cache.push(sh) }
      it { should include_sexp [:cmd, "rvm 1.9.3 --fuzzy do $CASHER_DIR/bin/casher push #{push_url}"] }
    end

    describe 'on a different branch' do
      let(:fetch_signature) { 'cbce59b97e29ba90e1810a9cbedc1d5cd76df8235064c0016a53dea232124d60' }
      let(:push_signature)  { '256ffe8e059f07c9d4e3f2491068fe22ad92722d120590e05671467fb5fda252' }
      let(:fallback_url)    { Shellwords.escape "#{url_for('master')}&X-Amz-Expires=20&X-Amz-Signature=#{master_fetch_signature}&X-Amz-SignedHeaders=host" }
      let(:branch)          { 'featurefoo' }

      describe 'fetch' do
        before { directory_cache.fetch(sh) }
        it { should include_sexp [:cmd, "rvm 1.9.3 --fuzzy do $CASHER_DIR/bin/casher fetch #{fetch_url} #{fallback_url} #{global_fallback}"] }
      end

      describe 'add' do
        before { directory_cache.add(sh, '/foo/bar') }
        it { should include_sexp [:cmd, 'rvm 1.9.3 --fuzzy do $CASHER_DIR/bin/casher add /foo/bar'] }
      end

      describe 'push' do
        before { directory_cache.push(sh) }
        it { should include_sexp [:cmd, "rvm 1.9.3 --fuzzy do $CASHER_DIR/bin/casher push #{push_url}"] }
      end
    end
  end
end
