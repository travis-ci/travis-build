require 'spec_helper'

describe Travis::Build::Script::DirectoryCache do
  let(:cache_options) {{
    fetch_timeout: 20,
    push_timeout: 30,
    s3: { bucket: 's3_bucket', secret_access_key: 's3_secret_access_key', access_key_id: 's3_access_key_id' },
    type: "s3"
  }}

  describe "dummy caching" do
    subject { Struct.new(:data) { include(Travis::Build::Script::DirectoryCache) }.new(data) }
    let(:data) { Travis::Build::Data.new(config: { cache: cache }, cache_options: cache_options) }

    describe "with no caching enabled" do
      let(:cache) {{ }}
      it { is_expected.not_to be_use_directory_cache }

      describe '#cache_class' do
        subject { super().cache_class }
        it { is_expected.to eq(Travis::Build::Script::DirectoryCache::Dummy) }
      end
    end

    describe "with caching enabled" do
      let(:cache) {{ directories: ["foo"] }}
      it { is_expected.to be_use_directory_cache }

      describe '#cache_class' do
        subject { super().cache_class }
        it { is_expected.to eq(Travis::Build::Script::DirectoryCache::S3) }
      end
    end

    describe "casher branch" do
      describe "normal mode" do
        let(:cache) {{ }}

        describe '#casher_branch' do
          subject { super().casher_branch }
          it { is_expected.to eq('production') }
        end
      end

      describe "passing branch" do
        let(:cache) {{ branch: 'foo' }}

        describe '#casher_branch' do
          subject { super().casher_branch }
          it { is_expected.to eq('foo') }
        end
      end

      describe "edge mode" do
        let(:cache) {{ edge: true }}

        describe '#casher_branch' do
          subject { super().casher_branch }
          it { is_expected.to eq('master') }
        end
      end
    end
  end

  describe "s3 caching" do
    describe "signatures" do
      it "works with Amazon's example" do
        key_pair = Travis::Build::Script::DirectoryCache::S3::KeyPair.new("AKIAIOSFODNN7EXAMPLE", "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY")
        location = Travis::Build::Script::DirectoryCache::S3::Location.new("https", "us-east-1", "examplebucket", "/test.txt")
        signature = Travis::Build::Script::DirectoryCache::S3::AWS4Signature.new(key_pair, "GET", location, 86400, Time.gm(2013, 5, 24))

        expect(signature.to_uri.query_values['X-Amz-Signature']).to eq("aeeed9bbccd4d02ee5c0109b86d86835f995330da4c265957d157751f604d404")
      end
    end

    url_pattern = "https://s3_bucket.s3.amazonaws.com/42/%s/example.tbz?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=s3_access_key_id%%2F19700101%%2Fus-east-1%%2Fs3%%2Faws4_request&X-Amz-Date=19700101T000010Z"
    let(:url) { url_pattern % branch }
    let(:global_fallback) { "https://s3_bucket.s3.amazonaws.com/42/example.tbz\\?X-Amz-Algorithm\\=AWS4-HMAC-SHA256\\&X-Amz-Credential\\=s3_access_key_id\\%2F19700101\\%2Fus-east-1\\%2Fs3\\%2Faws4_request\\&X-Amz-Date\\=19700101T000010Z\\&X-Amz-Expires\\=20\\&X-Amz-Signature\\=7f206e62deecd81668ca0093f051aeeaaff5c7f53dcf74186c468e4eef3c1e75\\&X-Amz-SignedHeaders\\=host" }
    let(:master_fetch_signature) { "163b2a236fcfda37d58c1d50c27d86fbd04efb4a6d97219134f71854e3e0383b" }
    let(:fetch_signature) { master_fetch_signature }
    let(:push_signature) { "926885a758f00d51eaad281522a26cf7151fdd530aa1272c1d8c607c2e778570" }
    let(:fetch_url) { Shellwords.escape "#{url}&X-Amz-Expires=20&X-Amz-Signature=#{fetch_signature}&X-Amz-SignedHeaders=host" }
    let(:push_url) { Shellwords.escape "#{url}&X-Amz-Expires=30&X-Amz-Signature=#{push_signature}&X-Amz-SignedHeaders=host" }
    let(:data) { Travis::Build::Data.new(config: {}, repository: repository, cache_options: cache_options, job: { branch: branch }) }
    let(:repository) {{ github_id: 42 }}
    let(:slug) { "ex a/mple" }
    let(:sh) { MockShell.new }
    let(:branch) { 'master' }

    subject(:directory_cache) do
      Travis::Build::Script::DirectoryCache::S3.new(data, slug, 'production', Time.at(10))
    end

    specify :install do
      directory_cache.install(sh)
      expect(sh.commands).to be == [
        "export CASHER_DIR=$HOME/.casher",
        "mkdir -p $CASHER_DIR/bin",
        "echo Installing caching utilities; curl https://raw.githubusercontent.com/travis-ci/casher/production/bin/casher -L -o $CASHER_DIR/bin/casher -s --fail",
        "[ $? -ne 0 ] && echo 'Failed to fetch casher from GitHub, disabling cache.' && echo > $CASHER_DIR/bin/casher",
        "chmod +x $CASHER_DIR/bin/casher"
      ]
    end

    specify :fetch do
      directory_cache.fetch(sh)
      expect(sh.commands).to be == ["rvm 1.9.3 --fuzzy do $CASHER_DIR/bin/casher fetch #{fetch_url} #{global_fallback}"]
    end

    specify :add do
      directory_cache.add(sh, "/foo/bar")
      expect(sh.commands).to be == ["rvm 1.9.3 --fuzzy do $CASHER_DIR/bin/casher add /foo/bar"]
    end

    specify :push do
      directory_cache.push(sh)
      expect(sh.commands).to be == ["rvm 1.9.3 --fuzzy do $CASHER_DIR/bin/casher push #{push_url}"]
    end

    describe "on a different branch" do
      let(:branch) { "featurefoo" }
      let(:fetch_signature) { "cbce59b97e29ba90e1810a9cbedc1d5cd76df8235064c0016a53dea232124d60" }
      let(:push_signature) { "256ffe8e059f07c9d4e3f2491068fe22ad92722d120590e05671467fb5fda252" }
      let(:fallback_url) { Shellwords.escape "#{url_pattern % 'master'}&X-Amz-Expires=20&X-Amz-Signature=#{master_fetch_signature}&X-Amz-SignedHeaders=host" }

      specify :fetch do
        directory_cache.fetch(sh)
        expect(sh.commands).to be == ["rvm 1.9.3 --fuzzy do $CASHER_DIR/bin/casher fetch #{fetch_url} #{fallback_url} #{global_fallback}"]
      end

      specify :add do
        directory_cache.add(sh, "/foo/bar")
        expect(sh.commands).to be == ["rvm 1.9.3 --fuzzy do $CASHER_DIR/bin/casher add /foo/bar"]
      end

      specify :push do
        directory_cache.push(sh)
        expect(sh.commands).to be == ["rvm 1.9.3 --fuzzy do $CASHER_DIR/bin/casher push #{push_url}"]
      end
    end
  end
end
