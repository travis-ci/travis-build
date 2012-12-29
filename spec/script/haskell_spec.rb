require 'spec_helper'

describe Travis::Build::Script::Haskell do
  let(:data) { PAYLOADS[:push].deep_clone }

  subject { described_class.new(data).compile }

  it_behaves_like 'a build script'

  it 'announces ghc --version' do
    should announce 'ghc --version'
  end

  it 'announces cabal --version' do
    should announce 'cabal --version'
  end

  it 'installs with cabal update && cabal install' do
    should run 'echo $ cabal update && cabal install'
    should run 'cabal update'
    should run 'cabal install', log: true, assert: true, timeout: timeout_for(:install)
  end

  it 'runs cabal configure --enable-tests && cabal build && cabal test' do
    should run 'echo $ cabal configure --enable-tests && cabal build && cabal test'
    should run 'cabal configure --enable-tests'
    should run 'cabal build'
    should run 'cabal test', log: true, timeout: timeout_for(:script)
  end
end
