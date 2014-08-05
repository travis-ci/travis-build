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
    is_expected.to travis_cmd "export PATH=/usr/local/ghc/$(ghc_find #{version})/bin/:$PATH"
  end

  it 'runs cabal update' do
    is_expected.to travis_cmd 'cabal update', retry: true
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
    is_expected.to travis_cmd 'cabal install --only-dependencies --enable-tests', echo: true, timing: true, assert: true, retry: true
  end

  it 'runs cabal configure --enable-tests && cabal build && cabal test' do
    is_expected.to travis_cmd 'cabal configure --enable-tests && cabal build && cabal test', echo: true, timing: true
  end
end
