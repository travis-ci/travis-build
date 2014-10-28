require 'spec_helper'

describe Travis::Build::Script::Addons::CodeClimate, :sexp do
  let(:config) { { :repo_token => '1234' } }
  let(:data)   { PAYLOADS[:push].deep_clone }
  let(:sh)     { Travis::Shell::Builder.new }
  let(:addon)  { described_class.new(sh, Travis::Build::Data.new(data), config) }
  subject      { sh.to_sexp }
  before       { addon.before_script }

  let(:export_repo_token) { [:export, ['CODECLIMATE_REPO_TOKEN', '1234']] }

  describe 'with a token' do
    it { should include_sexp export_repo_token }
  end

  describe 'without a token' do
    let(:config)  { {} }
    it { should_not include_sexp export_repo_token }
  end
end
