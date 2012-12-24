require 'spec_helper'

describe Travis::Build::Script::Perl do
  let(:config) { PAYLOADS[:push].deep_clone }

  subject { described_class.new(config).compile }

  it_behaves_like 'a build script'

  it 'sets TRAVIS_PERL_VERSION' do
    should set 'TRAVIS_PERL_VERSION', '5.14'
  end

  it 'sets up the perl version' do
    should run 'perlbrew use 5.14', echo: true, log: true, assert: true
  end

  it 'announces perl --version' do
    should run 'perl --version', echo: true, log: true
  end

  it 'announces cpanm --version' do
    should run 'cpanm --version', echo: true, log: true
  end

  it 'installs with ' do
    should run 'cpanm --quiet --installdeps --notest .', echo: true, assert: true, log: true, timeout: timeout_for(:install)
  end

  describe 'if no Build.PL or Makefile.PL exists' do
    it 'runs make test' do
      should run 'make test', echo: true, log: true, timeout: timeout_for(:script)
    end
  end

  describe 'if Build.PL exists' do
    before(:each) do
      file('Build.PL')
    end

    it 'runs perl Build.PL && ./Build test' do
      should run 'echo $ perl Build.PL && ./Build test'
      should run 'perl Build.PL'
      # TODO can't really capture this yet
      # should run './Build test', log: true, timeout: timeout_for(:script)
    end
  end

  describe 'if Makefile.PL exists' do
    before(:each) do
      file('Makefile.PL')
    end

    it 'runs perl Makefile.PL && make test' do
      should run 'echo $ perl Makefile.PL && make test'
      should run 'perl Makefile.PL'
      should run 'make test', log: true, timeout: timeout_for(:script)
    end
  end
end
