require 'spec_helper'

describe Travis::Build::Script::Php, :sexp do
  let(:data)   { PAYLOADS[:push].deep_clone }
  let(:script) { described_class.new(data) }
  subject      { script.sexp }

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
end
