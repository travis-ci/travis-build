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
      it { should_not be_use_directory_cache }
      its(:cache_class) { should be == Travis::Build::Script::DirectoryCache::Dummy }
    end

    describe "with caching enabled" do
      let(:cache) {{ directories: ["foo"] }}
      it { should be_use_directory_cache }
      its(:cache_class) { should be == Travis::Build::Script::DirectoryCache::S3 }
    end

    describe "casher branch" do
      describe "normal mode" do
        let(:cache) {{ }}
        its(:casher_branch) { should be == 'production' }
      end

      describe "edge mode" do
        let(:cache) {{ edge: true }}
        its(:casher_branch) { should be == 'master' }
      end
    end
  end

  describe "s3 caching" do
    url_pattern = "https://s3.amazonaws.com/s3_bucket/42/%s/example.tbz?AWSAccessKeyId=s3_access_key_id"
    let(:url) { url_pattern % branch }
    let(:global_fallback) { "https://s3.amazonaws.com/s3_bucket/42/example.tbz\\?AWSAccessKeyId\\=s3_access_key_id\\&Expires\\=30\\&Signature\\=rqO9wdTuwwSKUIx0lOfll1qooHw\\%3D" }
    let(:master_fetch_signature) { "qYxqzLotOvHutJy1jvyaGm%2F2BlE%3D" }
    let(:fetch_signature) { master_fetch_signature }
    let(:push_signature) { "OE1irmu2XzZqIAiSSfWjeslNq%2B8%3D" }
    let(:fetch_url) { Shellwords.escape "#{url}&Expires=30&Signature=#{fetch_signature}" }
    let(:push_url) { Shellwords.escape "#{url}&Expires=40&Signature=#{push_signature}" }
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
        "curl https://raw.github.com/travis-ci/casher/production/bin/casher -o $CASHER_DIR/bin/casher -s --fail",
        "[ $? -ne 0 ] && echo 'Failed to fetch casher from GitHub, disabling cache.' && echo > $CASHER_DIR/bin/casher",
        "chmod +x $CASHER_DIR/bin/casher"
      ]
    end

    specify :fetch do
      directory_cache.fetch(sh)
      expect(sh.commands).to be == ["rvm 1.9.3 do $CASHER_DIR/bin/casher fetch #{fetch_url} #{global_fallback}"]
    end

    specify :add do
      directory_cache.add(sh, "/foo/bar")
      expect(sh.commands).to be == ["rvm 1.9.3 do $CASHER_DIR/bin/casher add /foo/bar"]
    end

    specify :push do
      directory_cache.push(sh)
      expect(sh.commands).to be == ["rvm 1.9.3 do $CASHER_DIR/bin/casher push #{push_url}"]
    end

    describe "on a different branch" do
      let(:branch) { "featurefoo" }
      let(:fetch_signature) { "Y6Thq%2B%2BUyBhfqW5RJwaZL3zc4Ds%3D" }
      let(:push_signature) { "d55mUsXtHhHi2Wgxf6ftKqE52jA%3D" }
      let(:fallback_url) { Shellwords.escape "#{url_pattern % 'master'}&Expires=30&Signature=#{master_fetch_signature}" }

      specify :fetch do
        directory_cache.fetch(sh)
        expect(sh.commands).to be == ["rvm 1.9.3 do $CASHER_DIR/bin/casher fetch #{fetch_url} #{fallback_url} #{global_fallback}"]
      end

      specify :add do
        directory_cache.add(sh, "/foo/bar")
        expect(sh.commands).to be == ["rvm 1.9.3 do $CASHER_DIR/bin/casher add /foo/bar"]
      end

      specify :push do
        directory_cache.push(sh)
        expect(sh.commands).to be == ["rvm 1.9.3 do $CASHER_DIR/bin/casher push #{push_url}"]
      end
    end
  end
end