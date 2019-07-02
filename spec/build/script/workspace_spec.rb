require 'spec_helper'

describe Travis::Build::Script::Workspace, :sexp do
  let(:options) { { fetch_timeout: 20, push_timeout: 30, type: 's3', s3: { bucket: 's3_bucket', secret_access_key: 's3_secret_access_key', access_key_id: 's3_access_key_id' } } }
  let(:data)    { payload_for(:push, :ruby, config: config, cache_options: options) }
  let(:sh)      { Travis::Shell::Builder.new }
  let(:sexp)    { script.sexp }
  let(:script)  { Travis::Build.script(data) }
  let(:cache)   { script.directory_cache }
  subject       { script.sexp }

  it_behaves_like 'compiled script' do
    let(:config) { { workspaces: { use: "foo", create: { name: "bar", paths: ['build'] } } } }
    let(:cmds)   { ['workspaces_use'] }
    let(:cmds)   { ['workspaces_create'] }
  end

  describe 'when workspace name contains shell env var' do
    let(:config) { { workspaces: { use: "${TRAVIS_OS_NAME}", create: { name: "ws-${TRAVIS_OS_NAME}", paths: ['build'] } } } }
    it "interprets the env var" do
      store_example
      should include_sexp [
        :cmd,
        %r[\$CASHER_DIR/bin/casher --name ws-%24%7BTRAVIS_OS_NAME%7D workspace push https://s3.amazonaws.com/s3_bucket/workspaces/1/ws-\\\$\\\{TRAVIS_OS_NAME\\\}.tgz\\\?X-Amz-Algorithm\\\=AWS4-HMAC-SHA256\\\&X-Amz-Credential\\\=s3_access_key_id\\\%2F.*\\\%2Fus-east-1\\\%2Fs3\\\%2Faws4_request\\\&X-Amz-Date\\\=\d{8}T\d{6}Z\\\&X-Amz-Expires\\\=30\\\&X-Amz-Signature\\\=[a-f0-9]+\\\&X-Amz-SignedHeaders\\\=host],
        timing: true
      ]
    end
  end
end
