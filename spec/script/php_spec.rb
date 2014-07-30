require 'spec_helper'

describe Travis::Build::Script::Php do
  let(:options) { { logs: { build: false, state: false } } }
  let(:data)    { PAYLOADS[:push].deep_clone }

  subject { described_class.new(data, options).compile }

  after :all do
    store_example
  end

  it_behaves_like 'a build script'

  it 'sets TRAVIS_PHP_VERSION' do
    is_expected.to set 'TRAVIS_PHP_VERSION', '5.3'
  end

  it 'sets up the php version' do
    is_expected.to travis_cmd 'phpenv global 5.3', echo: true, timing: true, assert: true
  end

  it 'announces php --version' do
    is_expected.to announce 'php --version'
  end

  it 'announces composer --version' do
    is_expected.to announce 'composer --version'
  end

  it 'runs phpunit' do
    is_expected.to travis_cmd 'phpunit', echo: true, timing: true
  end
end
