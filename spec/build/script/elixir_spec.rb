require 'spec_helper'

describe Travis::Build::Script::Elixir, :sexp do
  let(:data)   { payload_for(:push, :elixir) }
  let(:script) { described_class.new(data) }
  subject      { script.sexp }

  it_behaves_like 'compiled script' do
    let(:code) { ['TRAVIS_LANGUAGE=elixir'] }
  end

  it_behaves_like 'a build script sexp'

  it 'sets TRAVIS_OTP_RELEASE' do
    should include_sexp [:export, ['TRAVIS_OTP_RELEASE', '17.5']] #, echo: true
  end

  it 'sets TRAVIS_ELIXIR_VERSION' do
    should include_sexp [:export, ['TRAVIS_ELIXIR_VERSION', '1.0.4']] #, echo: true
  end

  it 'announces elixir version' do
    should include_sexp [:cmd, 'elixir --version', echo: true]
  end

  describe 'install' do
    it 'runs "mix local.hex"' do
      should include_sexp [:cmd, 'mix local.hex --force', assert: true, echo: true, timing: true]
    end
    it 'runs "mix deps.get"' do
      should include_sexp [:cmd, 'mix deps.get',  assert: true, echo: true, timing: true]
    end
  end

  describe 'script' do
    it 'runs "mix test"' do
      should include_sexp [:cmd, 'mix test', echo: true, timing: true]
    end
  end

  describe '#cache_slug' do
    subject { described_class.new(data).cache_slug }
    it { is_expected.to eq('cache--otp-17.5--elixir-1.0.4') }
  end
end

