require 'spec_helper'

describe Travis::Build::Script::Elixir, :sexp do
  let(:data)   { payload_for(:push, :elixir) }
  let(:script) { described_class.new(data) }
  subject      { script.sexp }

  it_behaves_like 'compiled script' do
    let(:code) { ['TRAVIS_LANGUAGE=elixir'] }
    let(:cmds) { ['kiex use 1.0.2'] }
  end

  it_behaves_like 'a build script sexp'

  it 'sets TRAVIS_OTP_RELEASE' do
    should include_sexp [:export, ['TRAVIS_OTP_RELEASE', '17.3']] #, echo: true
  end

  it 'sets TRAVIS_ELIXIR_VERSION' do
    should include_sexp [:export, ['TRAVIS_ELIXIR_VERSION', '1.0.2']] #, echo: true
  end

  it 'uses elixir' do
    should include_sexp [:cmd, 'kiex use 1.0.2', echo: true]
  end

  it 'announces elixir version' do
    should include_sexp [:cmd, 'elixir --version', echo: true]
  end

  describe 'install' do
  end

  describe 'script' do
  end

  describe '#cache_slug' do
    subject { described_class.new(data).cache_slug }
    it { is_expected.to eq('cache--otp-17.3--elixir-1.0.2') }
  end
end

