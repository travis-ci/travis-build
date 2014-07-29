require 'spec_helper'

describe Travis::Build::Script::Addons::CodeClimate, :sexp do
  let(:data)   { Travis::Build::Data.new(PAYLOADS[:push].deep_clone) }
  let(:sh)     { Travis::Shell::Builder.new }
  let(:addon)  { described_class.new(sh, data, config) }
  subject      { sh.to_sexp }

  let(:export_repo_token) { [:export, ['CODECLIMATE_REPO_TOKEN', '1234']] }

  context 'with a token' do
    let(:config)  { { :repo_token => '1234' } }
    before(:each) { addon.before_script }
    it { should include_sexp export_repo_token }
  end

  context 'without a token' do
    let(:config)  { {} }
    before(:each) { addon.before_script }
    it { should_not include_sexp export_repo_token }
  end
end
