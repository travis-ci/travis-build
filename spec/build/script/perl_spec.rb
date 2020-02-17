require 'spec_helper'

describe Travis::Build::Script::Perl, :sexp do
  let(:data)   { payload_for(:push, :perl) }
  let(:script) { described_class.new(data) }
  subject      { script.sexp }
  it           { store_example }

  it_behaves_like 'a bash script'

  it_behaves_like 'compiled script' do
    let(:code) { ['TRAVIS_LANGUAGE=perl'] }
    let(:cmds) { ['./Build test'] }
  end

  it_behaves_like 'a build script sexp'

  it 'sets TRAVIS_PERL_VERSION' do
    should include_sexp [:export, ['TRAVIS_PERL_VERSION', '5.14']]
  end

  it 'sets up the perl version' do
    should include_sexp [:cmd, 'perlbrew use 5.14', echo: true, timing: true]
  end

  it 'converts 5.1 to 5.10' do
    data[:config][:perl] = 5.1
    should include_sexp [:cmd, 'perlbrew use 5.10', echo: true, timing: true]
  end

  it 'converts 5.2 to 5.20' do
    data[:config][:perl] = 5.2
    should include_sexp [:cmd, 'perlbrew use 5.20', echo: true, timing: true]
  end

  it 'accepts an array and use the first value' do
    data[:config][:perl] = %w( 5.22 )
    should include_sexp [:cmd, 'perlbrew use 5.22', echo: true, timing: true]
  end

  it 'announces perl --version' do
    should include_sexp [:cmd, 'perl --version', echo: true]
  end

  it 'announces cpanm --version' do
    should include_sexp [:cmd, 'cpanm --version', echo: true]
  end

  it 'installs' do
    should include_sexp [:cmd, 'cpanm --quiet --installdeps --notest .', assert: true, echo: true, retry: true, timing: true]
  end

  describe 'script' do
    let(:sexp) { sexp_find(subject, [:if, '-f Build.PL']) }

    it 'runs perl Build.PL && ./Build test if Build.PL exists' do
      branch = sexp_find(sexp, [:then])
      expect(branch).to include_sexp [:cmd, 'perl Build.PL && ./Build && ./Build test', echo: true, timing: true]
    end

    it 'runs perl Makefile.PL && make test if Makefile.PL exists' do
      branch = sexp_find(sexp, [:elif, '-f Makefile.PL'])
      expect(branch).to include_sexp [:cmd, 'perl Makefile.PL && make test', echo: true, timing: true]
    end

    it 'runs make test if no Build.PL or Makefile.PL exists' do
      branch = sexp_find(sexp, [:else])
      expect(branch).to include_sexp [:cmd, 'make test', echo: true, timing: true]
    end
  end
end

