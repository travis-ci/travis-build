require 'spec_helper'

describe Travis::Build::Script::Haskell, :sexp do
  let(:data)   { payload_for(:push, :haskell) }
  let(:script) { described_class.new(data) }
  subject      { script.sexp }
  it           { store_example }

  it_behaves_like 'a bash script'

  it_behaves_like 'compiled script' do
    let(:code) { ['TRAVIS_LANGUAGE=haskell'] }
    let(:cmds) { ['cabal test'] }
  end

  it_behaves_like 'a build script sexp'

  it "exports PATH variable" do
    should include_sexp [:export, ['PATH', "${TRAVIS_GHC_ROOT}/${TRAVIS_HASKELL_VERSION}/bin:${PATH}"], echo: true, assert: true]
  end

  it 'exports TRAVIS_HASKELL_VERSION variable' do
    data[:config][:ghc] = 'default'
    should include_sexp [:export, ['TRAVIS_HASKELL_VERSION', "$(travis_ghc_find '#{described_class::DEFAULTS[:ghc]}')"], echo: true]
  end

  it 'runs cabal update' do
    should include_sexp [:cmd, 'cabal update', assert: true, echo: true, retry: true, timing: true]
  end

  it 'announces ghc --version' do
    should include_sexp [:cmd, 'ghc --version', echo: true]
  end

  it 'announces cabal --version' do
    should include_sexp [:cmd, 'cabal --version', echo: true]
  end

  it 'installs with cabal install --only-dependencies --enable-tests' do
    should include_sexp [:cmd, 'cabal install --only-dependencies --enable-tests', assert: true, echo: true, retry: true, timing: true]
  end

  it 'runs cabal configure --enable-tests && cabal build && cabal test' do
    should include_sexp [:cmd, 'cabal configure --enable-tests && cabal build && cabal test', echo: true, timing: true]
  end

  [
    { ghc: '7.7.7', cabal: '1.11' },
    { ghc: '8.8.8', cabal: 'head' },
    { ghc: 'head', cabal: '1.23' },
    { ghc: 'head', cabal: 'head' },
  ].each do |ghc_config|
    context "when full ghc=#{ghc_config[:ghc]} and cabal=#{ghc_config[:cabal]} versions are given" do
      before do
        data[:config].merge!(ghc_config)
      end

      it 'checks for existing installation' do
        should include_sexp [:raw, %(if [[ ! $(travis_ghc_find #{ghc_config[:ghc]} &>/dev/null) || $(cabal --numeric-version 2>/dev/null) != #{ghc_config[:cabal]}* ]]; then)]
      end

      it 'installs ghc version when not present' do
        should include_sexp [:echo, %(Updating ghc-#{ghc_config[:ghc]} and cabal-#{ghc_config[:cabal]}), ansi: :yellow]
        should include_sexp [:raw, %(travis_ghc_install '#{ghc_config[:ghc]}' '#{ghc_config[:cabal]}')]
        should include_sexp [:export, ['TRAVIS_HASKELL_VERSION', %($(travis_ghc_find '#{ghc_config[:ghc]}'))], echo: true]
      end
    end
  end

  context 'when valid alias ghc version is given' do
    before do
      aliases = described_class::GHC_VERSION_ALIASES.dup.merge('rad' => '8.0.9')
      described_class.send(:remove_const, :GHC_VERSION_ALIASES)
      described_class.const_set(:GHC_VERSION_ALIASES, aliases)
      data[:config][:ghc] = 'rad'
    end

    it 'uses the resolved version' do
      should include_sexp [:export, ['TRAVIS_HASKELL_VERSION', %($(travis_ghc_find '8.0.9'))], echo: true]
    end
  end
end
