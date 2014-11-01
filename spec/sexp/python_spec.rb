require 'spec_helper'

describe Travis::Build::Script::Python, :sexp do
  let(:data)   { PAYLOADS[:push].deep_clone }
  let(:script) { described_class.new(data) }
  subject      { script.sexp }

  describe 'given a script' do
    before :each do
      data['config']['script'] = 'script'
    end

    it_behaves_like 'a build script sexp'
  end

  it 'sets TRAVIS_PYTHON_VERSION' do
    should include_sexp [:export,  ['TRAVIS_PYTHON_VERSION', '2.7']]
  end

  it 'sets up the python version (pypy)' do
    data['config']['python'] = 'pypy'
    should include_sexp [:cmd,  'source ~/virtualenv/pypy/bin/activate', assert: true, echo: true, timing: true]
  end

  it 'sets up the python version (pypy3)' do
    data['config']['python'] = 'pypy3'
    should include_sexp [:cmd,  'source ~/virtualenv/pypy3/bin/activate', assert: true, echo: true, timing: true]
  end

  it 'sets up the python version (2.7)' do
    should include_sexp [:cmd,  'source ~/virtualenv/python2.7/bin/activate', assert: true, echo: true, timing: true]
  end

  it 'announces python --version' do
    should include_sexp [:cmd,  'python --version', echo: true]
  end

  it 'announces pip --version' do
    should include_sexp [:cmd,  'pip --version', echo: true]
  end

  describe 'install' do
    let(:sexp) { sexp_find(subject, [:if, '-f Requirements.txt']) }

    it 'installs with pip if Requirements.txt exists' do
      branch = sexp_find(sexp, [:then])
      expect(branch).to include_sexp [:cmd,  'pip install -r Requirements.txt', assert: true, echo: true, retry: true, timing: true]
    end

    it 'installs with pip if requirements.txt exists' do
      branch = sexp_find(sexp, [:elif, '-f requirements.txt'])
      expect(branch).to include_sexp [:cmd,  'pip install -r requirements.txt', assert: true, echo: true, retry: true, timing: true]
    end

    it 'errors if no requirements file exists' do
      branch = sexp_find(sexp, [:else])
      expect(branch).to include_sexp [:echo, described_class::REQUIREMENTS_MISSING, ansi: :red]
    end
  end

  it 'sets up python with system site packages enabled' do
    data['config']['virtualenv'] = { 'system_site_packages' => true }
    should include_sexp [:cmd,  'source ~/virtualenv/python2.7_with_system_site_packages/bin/activate', assert: true, echo: true, timing: true]
  end
end
