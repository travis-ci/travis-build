require 'spec_helper'

describe Travis::Build::Script::Perl do
  let(:options) { { logs: { build: false, state: false } } }
  let(:data)    { PAYLOADS[:push].deep_clone }

  subject { described_class.new(data, options).compile }

  it_behaves_like 'a build script'

  it 'sets TRAVIS_PERL_VERSION' do
    is_expected.to set 'TRAVIS_PERL_VERSION', '5.14'
  end

  it 'sets up the perl version' do
    is_expected.to setup 'perlbrew use 5.14'
  end

  it 'announces perl --version' do
    is_expected.to announce 'perl --version'
  end

  it 'announces cpanm --version' do
    is_expected.to announce 'cpanm --version'
  end

  it 'installs with ' do
    is_expected.to install 'cpanm --quiet --installdeps --notest .', retry: true
  end

  describe 'if perl version is 5.10' do
    before(:each) do
      data['config']['perl'] = 5.1
    end

    it 'converts 5.1 to 5.10' do
      is_expected.to setup 'perlbrew use 5.10'
    end
  end

  describe 'if no Build.PL or Makefile.PL exists' do
    it 'runs make test' do
      is_expected.to run_script 'make test'
    end
  end

  describe 'if Build.PL exists' do
    before(:each) do
      file('Build.PL')
    end

    it 'runs perl Build.PL && ./Build test' do
      is_expected.to run 'echo $ perl Build.PL && ./Build && ./Build test'
      is_expected.to run 'perl Build.PL'
      # TODO can't really capture this yet
      # should run './Build test', log: true
    end
  end

  describe 'if Makefile.PL exists' do
    before(:each) do
      file('Makefile.PL')
    end

    it 'runs perl Makefile.PL && make test' do
      is_expected.to run 'echo $ perl Makefile.PL && make test'
      is_expected.to run 'perl Makefile.PL'
      is_expected.to run 'make test', log: true
    end
  end
end
