require 'spec_helper'

describe Travis::Build::Script::Workspace do
  let(:options) {}
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
