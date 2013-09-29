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
        its(:casher_branch) { should be == 'production'}
      end

      describe "edge mode" do
        let(:cache) {{ edge: true }}
        its(:casher_branch) { should be == 'master' }
      end
    end
  end

  describe "s3 caching" do
    let(:url) { "https://s3.amazonaws.com/s3_bucket/42/example.tbz?AWSAccessKeyId=s3_access_key_id" }
    let(:fetch_url) { Shellwords.escape "#{url}&Expires=30&Signature=rqO9wdTuwwSKUIx0lOfll1qooHw%3D" }
    let(:push_url) { Shellwords.escape "#{url}&Expires=40&Signature=n6HDsKG7qJbWnss3cXMPknrDq4c%3D" }
    let(:repository) {{ github_id: 42 }}
    let(:slug) { "example" }
    let(:sh) { MockShell.new }

    subject(:directory_cache) do
      Travis::Build::Script::DirectoryCache::S3.new(cache_options, repository, slug, 'production', Time.at(10))
    end

    specify :install do
      directory_cache.install(sh)
      expect(sh.commands).to be == [
        "export CASHER_DIR=$HOME/.casher",
        "mkdir -p $CASHER_DIR/bin",
        "curl https://raw.github.com/travis-ci/casher/production/bin/casher -o $CASHER_DIR/bin/casher",
        "chmod +x $CASHER_DIR/bin/casher"
      ]
    end

    specify :fetch do
      directory_cache.fetch(sh)
      expect(sh.commands).to be == ["$CASHER_DIR/bin/casher fetch #{fetch_url}"]
    end

    specify :add do
      directory_cache.add(sh, "/foo/bar")
      expect(sh.commands).to be == ["$CASHER_DIR/bin/casher add /foo/bar"]
    end

    specify :push do
      directory_cache.push(sh)
      expect(sh.commands).to be == ["$CASHER_DIR/bin/casher push #{push_url}"]
    end
  end
end