require 'spec_helper'

describe Travis::Build::Script::Haskell do
  let(:options) { { logs: { build: false, state: false } } }
  let(:data)    { PAYLOADS[:push].deep_clone }

  subject { described_class.new(data, options).compile }

  after :all do
    store_example
  end

  it_behaves_like 'a build script'

  it "exports PATH variable" do
    version = "version"
    data['config']['ghc'] = version
    is_expected.to run "/usr/local/ghc/$(ghc_find #{version})/bin/:$PATH"
  end

  it 'runs cabal update' do
    is_expected.to run 'cabal update', retry: true
  end

  it 'folds cabal update' do
    is_expected.to fold 'cabal update', 'cabal'
  end

  it 'announces ghc --version' do
    is_expected.to announce 'ghc --version'
  end

  it 'announces cabal --version' do
    is_expected.to announce 'cabal --version'
  end

  it 'installs with cabal install --only-dependencies --enable-tests' do
    is_expected.to run 'echo $ cabal install --only-dependencies --enable-tests'
    is_expected.to run 'cabal install --only-dependencies --enable-tests', log: true, assert: true, timeout: timeout_for(:install), retry: true
  end

  it 'runs cabal configure --enable-tests && cabal build && cabal test' do
    is_expected.to run 'echo $ cabal configure --enable-tests && cabal build && cabal test'
    is_expected.to run 'cabal configure --enable-tests'
    is_expected.to run 'cabal build'
    is_expected.to run 'cabal test', log: true, timeout: timeout_for(:script)
  end
end
