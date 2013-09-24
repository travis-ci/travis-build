require 'spec_helper'

describe Travis::Build::Script::DirectoryCache do
  let(:fetch_url) { "https://s3.amazonaws.com/s3_bucket42-1.1?AWSAccessKeyId=s3_access_key_id&Expires=30&Signature=erYhl20RDdL8txHRHqeGgdbnYDw%3D" }
  let(:push_url) { "https://s3.amazonaws.com/s3_bucket42-1.1?AWSAccessKeyId=s3_access_key_id&Expires=40&Signature=2PVLxX3zPsu4NDYKz%2FCHEF7Xc4w%3D" }
  let(:repository) {{ github_id: 42 }}
  let(:job) {{ number: "1.1" }}
  let(:sh) { MockShell.new }
  let(:cache_options) {{
    fetch_timeout: 20,
    push_timeout: 30,
    s3: { bucket: 's3_bucket', secret_access_key: 's3_secret_access_key', access_key_id: 's3_access_key_id' }
  }}

  subject(:directory_cache) do
    Travis::Build::Script::DirectoryCache::S3.new(cache_options, repository, job, 10)
  end

  specify :install do
    directory_cache.install(sh)
    expect(sh.commands).to be == [
      "export CASHER_DIR=$HOME/.casher",
      "mkdir -p $CASHER_DIR/bin",
      "curl https://raw.github.com/rkh/casher/master/bin/casher -o $CASHER_DIR/bin/casher",
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