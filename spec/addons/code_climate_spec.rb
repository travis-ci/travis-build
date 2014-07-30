require 'spec_helper'

describe Travis::Build::Script::Addons::CodeClimate, :sexp do
  let(:data)   { PAYLOADS[:push].deep_clone }
  let(:script) { Travis::Build::Script.new(data) }
  let(:sh)     { script.sh }
  let(:addon)  { described_class.new(script, config) }
  subject      { sh.to_sexp }

  let(:export_repo_token) { [:export, ['CODECLIMATE_REPO_TOKEN', '1234']] }

  describe 'with a token' do
    let(:config)  { { :repo_token => '1234' } }
    before(:each) { addon.before_script }
    it { should include_sexp export_repo_token }
  end

  describe 'without a token' do
    let(:config)  { {} }
    before(:each) { addon.before_script }
    it { should_not include_sexp export_repo_token }
  end
end
