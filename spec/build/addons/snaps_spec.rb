require "spec_helper"

describe Travis::Build::Addons::Snaps, :sexp do
  let(:script) { stub('script') }
  let(:config) { ['travis', { name: 'aws-cli', classic: true }] }
  let(:data)   { payload_for(:push, :ruby, config: { dist: 'xenial', addons: { snaps: config } }) }
  let(:sh)     { Travis::Shell::Builder.new }
  let(:addon)  { described_class.new(script, sh, Travis::Build::Data.new(data), config) }
  subject      { sh.to_sexp }
  before       { addon.before_prepare }

  it { store_example }

  it_behaves_like 'compiled script' do
    let(:cmds) { ['sudo snap install travis'] }
  end

  it { should include_sexp [:cmd, "sudo snap install core", echo: true, timing: true, assert: true] }
  it { should include_sexp [:cmd, "sudo snap install travis", echo: true, timing: true, assert: true] }
  it { should include_sexp [:cmd, "sudo snap install aws-cli --classic", echo: true, timing: true, assert: true] }
  it { should include_sexp [:cmd, "sudo snap list", echo: true, timing: true, assert: true] }
end
