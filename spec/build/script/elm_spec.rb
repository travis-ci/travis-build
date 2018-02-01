require 'spec_helper'

describe Travis::Build::Script::Elm, :sexp do
  let(:data)   { payload_for(:push, :elm) }
  let(:script) { described_class.new(data) }
  subject      { script.sexp }
  it           { store_example }

  it_behaves_like 'compiled script' do
    let(:code) { ['TRAVIS_LANGUAGE=elm'] }
    let(:cmds) { ['elm-test'] }
  end

  it_behaves_like 'a build script sexp'

  it 'sets TRAVIS_ELM_VERSION' do
    should include_sexp [:export, ['TRAVIS_ELM_VERSION', Travis::Build::Script::Elm::DEFAULTS[:elm_version]]]
  end

  it 'sets TRAVIS_ELM_TEST_VERSION' do
    should include_sexp [:export, ['TRAVIS_ELM_TEST_VERSION', Travis::Build::Script::Elm::DEFAULTS[:elm_test_version]]]
  end

  it 'announces elm version' do
    should include_sexp [:cmd, 'elm --version', echo: true]
    should include_sexp [:cmd, 'elm-test --version', echo: true]
  end

  describe 'script' do
    it 'runs "elm-test"' do
      should include_sexp [:cmd, 'elm-test', echo: true, timing: true]
    end
  end

  describe '#cache_slug' do
    subject { described_class.new(data).cache_slug }
    it { is_expected.to eq("cache-#{CACHE_SLUG_EXTRAS}--node--elm-#{Travis::Build::Script::Elm::DEFAULTS[:elm_version]}") }
  end
end
