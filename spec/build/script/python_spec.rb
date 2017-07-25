require 'spec_helper'

describe Travis::Build::Script::Python, :sexp do
  let(:data)   { payload_for(:push, :python) }
  let(:script) { described_class.new(data) }
  subject      { script.sexp }
  it           { store_example }

  it_behaves_like 'compiled script' do
    let(:code) { ['TRAVIS_LANGUAGE=python'] }
    let(:cmds) { ['pip install'] }
  end

  describe 'given a script' do
    before :each do
      data[:config][:script] = 'script'
    end

    it_behaves_like 'a build script sexp'
  end

  it 'sets TRAVIS_PYTHON_VERSION' do
    should include_sexp [:export,  ['TRAVIS_PYTHON_VERSION', '2.7']]
  end

  it 'sets up the python version (pypy)' do
    data[:config][:python] = 'pypy'
    should include_sexp [:cmd,  'source ~/virtualenv/pypy/bin/activate', assert: true, echo: true, timing: true]
    should include_sexp [:cmd,  "curl -s -o pypy.tar.bz2 ${archive_url}", assert: true]
  end

  it 'sets up the python version (pypy-5.3.1)' do
    data[:config][:python] = 'pypy-5.3.1'
    should include_sexp [:cmd,  'source ~/virtualenv/pypy-5.3.1/bin/activate', assert: true, echo: true, timing: true]
    should include_sexp [:cmd,  "curl -s -o pypy-5.3.1.tar.bz2 ${archive_url}", assert: true]
    should include_sexp [:cmd,  "rm pypy-5.3.1.tar.bz2"]
  end

  it 'sets up the python version (pypy3.3-5.2-alpha1)' do
    data[:config][:python] = 'pypy3.3-5.2-alpha1'
    should include_sexp [:cmd,  'source ~/virtualenv/pypy3.3-5.2-alpha1/bin/activate', assert: true, echo: true, timing: true]
    should include_sexp [:cmd,  "curl -s -o pypy3.3-5.2-alpha1.tar.bz2 ${archive_url}", assert: true]
    should include_sexp [:cmd,  "rm pypy3.3-5.2-alpha1.tar.bz2"]
  end

  it 'sets up the python version (pypy3)' do
    data[:config][:python] = 'pypy3'
    should include_sexp [:cmd,  "curl -s -o pypy3.tar.bz2 ${archive_url}", assert: true]
    should include_sexp [:cmd,  'source ~/virtualenv/pypy3/bin/activate', assert: true, echo: true, timing: true]
  end

  it 'sets up the python version (2.7)' do
    should include_sexp [:cmd,  'source ~/virtualenv/python2.7/bin/activate', assert: true, echo: true, timing: true]
  end

  it 'sets up the python version nightly' do
    data[:config][:python] = 'nightly'
    should include_sexp [:cmd,  'sudo tar xjf python-nightly.tar.bz2 --directory /', echo: true, assert: true]
    should include_sexp [:cmd,  'source ~/virtualenv/pythonnightly/bin/activate', assert: true, echo: true, timing: true]
  end

  context 'when specified Python is not pre-installed' do
    let(:version) { '2.7' }
    let(:sexp) { sexp_find(subject, [:if, "! -f ~/virtualenv/python#{version}/bin/activate"]) }

    it "downloads archive" do
      branch = sexp_find(sexp, [:then])
      expect(branch).to include_sexp [:raw, "archive_url=https://s3.amazonaws.com/travis-python-archives/binaries/${travis_host_os}/${travis_rel_version}/$(uname -m)/python-#{version}.tar.bz2"]
    end
  end

  it 'announces python --version' do
    should include_sexp [:cmd,  'python --version', echo: true]
  end

  it 'announces pip --version' do
    should include_sexp [:cmd,  'pip --version', echo: true]
  end

  describe 'install' do
    let(:sexp) { sexp_find(subject, [:if, '-f Requirements.txt']) }
    let(:options) { { fetch_timeout: 20, push_timeout: 30, type: 's3', s3: { bucket: 's3_bucket', secret_access_key: 's3_secret_access_key', access_key_id: 's3_access_key_id' } } }
    let(:data)   { payload_for(:push, :python, config: { cache: 'pip' }, cache_options: options) }

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
      expect(branch).to include_sexp [:echo, described_class::REQUIREMENTS_MISSING] #, ansi: :red
    end

    it 'adds $HOME/.cache/pip to directory cache' do
      should include_sexp [:cmd, 'rvm $(travis_internal_ruby) --fuzzy do $CASHER_DIR/bin/casher add $HOME/.cache/pip', timing: true]
    end
  end

  it 'sets up python with system site packages enabled' do
    data[:config][:virtualenv] = { 'system_site_packages' => true }
    should include_sexp [:cmd,  'source ~/virtualenv/python2.7_with_system_site_packages/bin/activate', assert: true, echo: true, timing: true]
  end
end
