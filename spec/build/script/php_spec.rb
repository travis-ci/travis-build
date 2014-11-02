require 'spec_helper'

describe Travis::Build::Script::Php, :sexp do
  let(:data)   { payload_for(:push, :php) }
  let(:script)   { described_class.new(data) }
  subject(:sexp) { script.sexp }

  it_behaves_like 'compiled script' do
    let(:code) { ['TRAVIS_LANGUAGE=php', 'phpunit'] }
  end

  it_behaves_like 'a build script sexp'

  it 'sets TRAVIS_PHP_VERSION' do
    should include_sexp [:export, ['TRAVIS_PHP_VERSION', '5.5']]
  end

  it 'sets up the php version' do
    should include_sexp [:cmd, 'phpenv global 5.5', echo: true, timing: true, assert: true]
  end

  it 'announces php --version' do
    should include_sexp [:cmd, 'php --version', echo: true]
  end

  it 'announces composer --version' do
    should include_sexp [:cmd, 'composer --version', echo: true]
  end

  it 'runs phpunit' do
    should include_sexp [:cmd, 'phpunit', echo: true, timing: true]
  end

  describe 'before_install' do
    subject { sexp_filter(sexp, [:if, '-f composer.json'])[0] }

    it 'runs composer self-update if composer.json exists' do
      should include_sexp [:cmd, 'composer self-update', assert: true, echo: true, timing: true]
    end
  end

  describe 'install' do
    subject { sexp_filter(sexp, [:if, '-f composer.json'])[1] }

    describe 'runs composer install if composer.json exists' do
      it { should include_sexp [:cmd, 'composer install', assert: true, echo: true, timing: true] }
    end

    describe 'uses given composer_args' do
      before { data[:config].update(composer_args: '--some --args') }
      it { should include_sexp [:cmd, 'composer install --some --args', assert: true, echo: true, timing: true] }
    end
  end
end
