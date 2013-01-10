require 'spec_helper'

describe Travis::Build::Script::Php do
  let(:options) { { logs: { build: true, state: true } } }
  let(:data)    { PAYLOADS[:push].deep_clone }

  subject { described_class.new(data, options).compile }

  after :all do
    store_example
  end

  it_behaves_like 'a build script'

  it 'sets TRAVIS_PHP_VERSION' do
    should set 'TRAVIS_PHP_VERSION', '5.3'
  end

  it 'sets up the php version' do
    should setup 'phpenv global 5.3'
  end

  it 'announces php --version' do
    should announce 'php --version'
  end

  it 'runs phpunit' do
    should run_script 'phpunit'
  end
end
