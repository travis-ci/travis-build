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
    store_example
    should include_sexp [:export, ['TRAVIS_ELM_VERSION', Travis::Build::Script::Elm::DEFAULTS[:elm]]]
  end

  context "given 'elm: 0.18.0'" do
    it "sets TRAVIS_ELM_VERSION to 0.18.0; prefixes TRAVIS_ELM_*_VERSION with 'elm'" do
      data[:config][:elm] = '0.18.0'
      should include_sexp [:export, ['TRAVIS_ELM_VERSION', '0.18.0']]
      should include_sexp [:export, ['TRAVIS_ELM_TEST_VERSION', 'elm0.18.0']]
      should include_sexp [:export, ['TRAVIS_ELM_FORMAT_VERSION', 'elm0.18.0']]
    end
  end

  context "given 'elm: elm0.18.0'" do
    it "sets TRAVIS_ELM_* environment variables to elm0.18.0" do
      data[:config][:elm] = 'elm0.18.0'
      should include_sexp [:export, ['TRAVIS_ELM_VERSION', 'elm0.18.0']]
      should include_sexp [:export, ['TRAVIS_ELM_TEST_VERSION', 'elm0.18.0']]
      should include_sexp [:export, ['TRAVIS_ELM_FORMAT_VERSION', 'elm0.18.0']]
    end
  end

  context "given 'elm: [elm0.18.0]'" do
    it "sets TRAVIS_ELM_* environment variables to elm0.18.0" do
      data[:config][:elm] = ['elm0.18.0']
      should include_sexp [:export, ['TRAVIS_ELM_VERSION', 'elm0.18.0']]
      should include_sexp [:export, ['TRAVIS_ELM_TEST_VERSION', 'elm0.18.0']]
      should include_sexp [:export, ['TRAVIS_ELM_FORMAT_VERSION', 'elm0.18.0']]
    end
  end

  context "given 'elm_test: elm0.18.0'" do
    it "sets TRAVIS_ELM_* environment variables correctly" do
      data[:config][:elm_test] = 'elm0.18.0'
      should include_sexp [:export, ['TRAVIS_ELM_VERSION', 'elm0.19.0']]
      should include_sexp [:export, ['TRAVIS_ELM_TEST_VERSION', 'elm0.18.0']]
      should include_sexp [:export, ['TRAVIS_ELM_FORMAT_VERSION', 'elm0.19.0']]
    end
  end

  it 'announces elm version' do
    should include_sexp [:cmd, 'elm --version', echo: true]
    should include_sexp [:cmd, 'elm-test --version', echo: true]
    should include_sexp [:cmd, 'elm-format --help | head -n 1', echo: true]
  end

  describe 'script' do
    it 'runs `elm-test` and `elm-format`' do
      should include_sexp [:cmd, 'elm-format --validate . && elm-test', echo: true, timing: true]
    end
  end

  describe '#cache_slug' do
    subject { described_class.new(data).cache_slug }
    it { is_expected.to eq("cache-#{CACHE_SLUG_EXTRAS}--node--elm-#{Travis::Build::Script::Elm::DEFAULTS[:elm]}") }
  end
end
