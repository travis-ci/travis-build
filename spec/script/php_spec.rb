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
    is_expected.to set 'TRAVIS_PHP_VERSION', '5.5'
  end

  it 'sets up the php version' do
    is_expected.to travis_cmd 'phpenv global 5.5', echo: true, timing: true, assert: true
  end

  it 'announces php --version' do
    is_expected.to announce 'php --version'
  end

  it 'announces composer --version' do
    is_expected.to announce 'composer --version'
  end

  context 'with a composer.json' do
    before do
      file 'composer.json'
      data['config']['composer_args'] = '--prefer-dist'
    end

    it 'folds composer self-update' do
      is_expected.to fold 'composer self-update', 'before_install.update_composer'
    end

    it 'runs composer install' do
      is_expected.to travis_cmd 'composer install --prefer-dist', echo: true
    end

    context 'and a checked-in composer.phar' do
      before do
        file 'composer.phar'
      end

      #it 'does not fold composer self-update' do
      #  is_expected.not_to fold 'composer self-update', 'before_install.update_composer'
      #end

      it 'runs composer.phar install' do
        is_expected.to travis_cmd 'composer.phar install --prefer-dist', echo: true
      end
    end
  end

  it 'runs phpunit' do
    is_expected.to travis_cmd 'phpunit', echo: true, timing: true
  end
end
