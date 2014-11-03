require 'spec_helper'

describe Travis::Build::Script::Haskell, :sexp do
  let(:data)   { payload_for(:push, :haskell) }
  let(:script) { described_class.new(data) }
  subject      { script.sexp }

  it_behaves_like 'compiled script' do
    let(:code) { ['TRAVIS_LANGUAGE=haskell'] }
    let(:cmds) { ['cabal test'] }
  end

  it_behaves_like 'a build script sexp'

  it "exports PATH variable" do
    version = "version"
    data[:config][:ghc] = version
    should include_sexp [:export, ['PATH', "/usr/local/ghc/$(ghc_find #{version})/bin/:$PATH"], echo: true]
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
end
