require 'spec_helper'

describe Travis::Build::Script::Haskell do
  let(:options) { { logs: { build: false, state: false } } }
  let(:data)    { PAYLOADS[:push].deep_clone }

  subject { described_class.new(data, options).compile }

  after :all do
    store_example
  end

  it_behaves_like 'a build script'

  it 'announces ghc --version' do
    should announce 'ghc --version'
  end

  it 'announces cabal --version' do
    should announce 'cabal --version'
  end

  it 'installs with cabal install --only-dependencies --enable-tests' do
    should run 'echo $ cabal install --only-dependencies --enable-tests'
    should run 'cabal install --only-dependencies --enable-tests', log: true, assert: true, timeout: timeout_for(:install)
  end

  it 'runs cabal configure --enable-tests && cabal build && cabal test' do
    should run 'echo $ cabal configure --enable-tests && cabal build && cabal test'
    should run 'cabal configure --enable-tests'
    should run 'cabal build'
    should run 'cabal test', log: true, timeout: timeout_for(:script)
  end
end
