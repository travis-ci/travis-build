require 'spec_helper'

describe Travis::Build::Script::DirectoryCache do
  let(:url) { "https://s3.amazonaws.com/s3_bucket/42/example.tbz?AWSAccessKeyId=s3_access_key_id" }
  let(:fetch_url) { Shellwords.escape "#{url}&Expires=30&Signature=R%2FJ%2B7kPMmMCPWC15qqv7DFpAK0c%3D" }
  let(:push_url) { Shellwords.escape "#{url}&Expires=40&Signature=SDuLvBYHMJXYhK50hQFI%2BiZcUJ4%3D" }
  let(:repository) {{ github_id: 42 }}
  let(:slug) { "example" }
  let(:sh) { MockShell.new }
  let(:cache_options) {{
    fetch_timeout: 20,
    push_timeout: 30,
    s3: { bucket: 's3_bucket', secret_access_key: 's3_secret_access_key', access_key_id: 's3_access_key_id' }
  }}

  subject(:directory_cache) do
    Travis::Build::Script::DirectoryCache::S3.new(cache_options, repository, slug, Time.at(10))
  end

  specify :install do
    directory_cache.install(sh)
    expect(sh.commands).to be == [
      "export CASHER_DIR=$HOME/.casher",
      "mkdir -p $CASHER_DIR/bin",
      "curl https://raw.github.com/travis-ci/casher/master/bin/casher -o $CASHER_DIR/bin/casher",
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