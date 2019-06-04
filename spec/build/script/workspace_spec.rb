require 'spec_helper'

describe Travis::Build::Script::Workspace, :sexp do
  let(:options) { { fetch_timeout: 20, push_timeout: 30, type: 's3', s3: { bucket: 's3_bucket', secret_access_key: 's3_secret_access_key', access_key_id: 's3_access_key_id' } } }
  let(:data)    { payload_for(:push, :ruby, config: config, cache_options: options) }
  let(:sh)      { Travis::Shell::Builder.new }
  let(:sexp)    { script.sexp }
  let(:script)  { Travis::Build.script(data) }
  let(:cache)   { script.directory_cache }

  it_behaves_like 'compiled script' do
    let(:config) { { workspaces: { use: "foo", create: { name: "foo" } } } }
    let(:cmds)   { ['workspaces_use'] }
    let(:cmds)   { ['workspaces_create'] }
  end

end
