require "spec_helper"

describe Travis::Build::Addons::Hostname, :sexp do
  let(:script) { stub('script') }
  let(:config) { 'newhostname' }
  let(:data)   { payload_for(:push, :ruby, config: { addons: { hostname: config } }) }
  let(:sh)     { Travis::Shell::Builder.new }
  let(:addon)  { described_class.new(script, sh, Travis::Build::Data.new(data), config) }
  subject      { sh.to_sexp }
  before       { addon.after_prepare }

  it { store_example }

  it_behaves_like 'compiled script' do
    let(:cmds) { ['hostname'] }
  end

  it { should include_sexp [:cmd, "sudo hostname #{config}", echo: true] }
end

