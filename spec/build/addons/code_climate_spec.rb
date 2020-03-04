require 'spec_helper'

describe Travis::Build::Addons::CodeClimate, :sexp do
  let(:script) { stub('script') }
  let(:data)   { payload_for(:push, :ruby, config: { addons: { code_climate: config } }) }
  let(:config) { { repo_token: '1234' } }
  let(:sh)     { Travis::Shell::Builder.new }
  let(:addon)  { described_class.new(script, sh, Travis::Build::Data.new(data), config) }
  subject      { sh.to_sexp }
  before       { addon.before_before_script }

  let(:export_repo_token) { [:export, ['CODECLIMATE_REPO_TOKEN', '1234']] }

  it_behaves_like 'compiled script' do
    let(:code) { ['CODECLIMATE_REPO_TOKEN="1234"'] }
  end

  describe 'with a token' do
    it { should include_sexp export_repo_token }
    it { store_example }
  end

  describe 'without a token' do
    let(:config)  { {} }
    it { should_not include_sexp export_repo_token }
  end
end
