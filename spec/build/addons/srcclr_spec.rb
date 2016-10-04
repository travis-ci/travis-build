require 'spec_helper'

describe Travis::Build::Addons::Srcclr, :sexp do
  let(:script) { stub('script') }
  let(:config) { {} }
  let(:data)   { payload_for(:push, :ruby, config: { addons: { srcclr: config } }) }
  let(:sh)     { Travis::Shell::Builder.new }
  let(:addon)  { described_class.new(script, sh, Travis::Build::Data.new(data), config) }
  subject      { sh.to_sexp }
  before       { addon.before_finish }

  context 'given empty config' do
    let(:config) { }
    it {
      should include_sexp [:echo, 'Unknown option \'\\{\\}\' specified. Not including srcclr addon.']
    }
  end

  context 'given empty quotes config' do
    let(:config) { '' }
    it {
      should include_sexp [:echo, 'Unknown option \'\'\'\' specified. Not including srcclr addon.']
    }
  end

  context 'given true config' do
    let(:config) { 'TrUe' }
    it {
      should include_sexp [:cmd, 'curl -sSL https://download.sourceclear.com/ci.sh | bash', {:echo=>true, :timing=>true}]
    }
  end

  context 'given false config' do
    let(:config) { 'FaLsE' }
    it {
      should include_sexp [:echo, 'srcclr: false specified. Not including srcclr addon.']
    }
  end

end
