require 'spec_helper'

describe Travis::Build::Script::Perl do
  let(:options) { { logs: { build: false, state: false } } }
  let(:data)    { PAYLOADS[:push].deep_clone }

  subject { described_class.new(data, options).compile }

  after :all do
    store_example
  end

  it_behaves_like 'a build script'

  it 'sets TRAVIS_PERL_VERSION' do
    is_expected.to set 'TRAVIS_PERL_VERSION', '5.14', echo: false
  end

  it 'sets up the perl version' do
    is_expected.to travis_cmd 'perlbrew use 5.14', echo: true, timing: true, assert: true
  end

  it 'announces perl --version' do
    is_expected.to announce 'perl --version'
  end

  it 'announces cpanm --version' do
    is_expected.to announce 'cpanm --version'
  end

  it 'installs with ' do
    is_expected.to travis_cmd 'cpanm --quiet --installdeps --notest .', echo: true, timing: true, assert: true, retry: true
  end

  describe 'if perl version is 5.10' do
    before(:each) do
      data['config']['perl'] = 5.1
    end

    it 'converts 5.1 to 5.10' do
      is_expected.to travis_cmd 'perlbrew use 5.10', echo: true, timing: true, assert: true
    end
  end

  describe 'if perl version is 5.20' do
    before(:each) do
      data['config']['perl'] = 5.2
    end

    it 'converts 5.2 to 5.20' do
      is_expected.to travis_cmd 'perlbrew use 5.20', echo: true, timing: true, assert: true
    end
  end

  describe 'if no Build.PL or Makefile.PL exists' do
    it 'runs make test' do
      is_expected.to travis_cmd 'make test', echo: true, timing: true
    end
  end

  describe 'if Build.PL exists' do
    before(:each) do
      file('Build.PL')
    end

    it 'runs perl Build.PL && ./Build test' do
      is_expected.to travis_cmd 'perl Build.PL && ./Build && ./Build test', echo: true, timing: true
    end
  end

  describe 'if Makefile.PL exists' do
    before(:each) do
      file('Makefile.PL')
    end

    it 'runs perl Makefile.PL && make test' do
      is_expected.to travis_cmd 'perl Makefile.PL && make test', echo: true, timing: true
    end
  end
end
