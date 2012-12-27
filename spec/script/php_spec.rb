require 'spec_helper'

describe Travis::Build::Script::Php do
  let(:config) { PAYLOADS[:push].deep_clone }

  subject { described_class.new(config).compile }

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
