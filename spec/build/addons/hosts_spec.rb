require "spec_helper"

describe Travis::Build::Addons::Hosts, :sexp do
  let(:script) { stub('script') }
  let(:config) { 'one.local two.local' }
  let(:data)   { payload_for(:push, :ruby, config: { addons: { hosts: config } }) }
  let(:sh)     { Travis::Shell::Builder.new }
  let(:addon)  { described_class.new(script, sh, Travis::Build::Data.new(data), config) }
  subject      { sh.to_sexp }
  before       { addon.after_prepare }

  it { store_example }

  it_behaves_like 'compiled script' do
    let(:cmds) { ['one.local two.local'] }
  end

  # it { should include_sexp [:cmd, "sed -e 's/^\\(127\\.0\\.0\\.1.*\\)$/\\1 'one.local\\ two.local'/' -i'.bak' /etc/hosts", sudo: true] }
  # it { should include_sexp [:cmd, "sed -e 's/^\\(::1.*\\)$/\\1 'one.local\\ two.local'/' -i'.bak' /etc/hosts", sudo: true] }
  it { should include_sexp [:cmd, "sed -e 's/^\\(127\\.0\\.0\\.1.*\\)$/\\1 one.local\\ two.local/' /etc/hosts > /tmp/hosts"] }
  it { should include_sexp [:cmd, "cat /tmp/hosts | sudo tee /etc/hosts > /dev/null"] }
end

