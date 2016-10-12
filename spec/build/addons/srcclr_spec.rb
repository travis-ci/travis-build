require 'spec_helper'

describe Travis::Build::Addons::Srcclr, :sexp do
  let(:script) { stub('script') }
  let(:config) { {} }
  let(:data)   { payload_for(:push, :ruby, config: { addons: { srcclr: config } }) }
  let(:sh)     { Travis::Shell::Builder.new }
  let(:addon)  { described_class.new(script, sh, Travis::Build::Data.new(data), config) }
  subject      { sh.to_sexp }
  before       { addon.before_finish }

  context 'given true config' do
    let(:config) { true }
    it {
      should include_sexp [:cmd, 'curl -sSL https://download.sourceclear.com/ci.sh |  bash', {:echo=>true, :timing=>true}]
    }
  end

 context 'given true config' do
    let(:config) { { debug: true } }
    it {
      should include_sexp [:cmd, 'curl -sSL https://download.sourceclear.com/ci.sh | env DEBUG=1 bash', {:echo=>true, :timing=>true}]
    }
  end

end
