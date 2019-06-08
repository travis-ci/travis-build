require 'spec_helper'

describe Travis::Build::Script::Python, :sexp do
  let(:data)   { payload_for(:push, :python) }
  let(:script) { described_class.new(data) }
  subject      { script.sexp }
  it           { store_example }
  it           { store_example(integration: true) }

  it_behaves_like 'a bash script', integration: true do
    let(:bash_script_file) { bash_script_path(integration: true) }
  end

  it_behaves_like 'a bash script'

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
    should include_sexp [:export,  ['TRAVIS_PYTHON_VERSION', '3.6']]
  end

  it 'sets up the python version (pypy)' do
    data[:config][:python] = 'pypy'
    should include_sexp [:cmd,  'source ~/virtualenv/pypy/bin/activate', assert: true, echo: true, timing: true]
    should include_sexp [:cmd,  "curl -sSf -o pypy.tar.bz2 ${archive_url}", echo: true, timing: true]
  end

  it 'sets up the python version (pypy-5.3.1)' do
    data[:config][:python] = 'pypy-5.3.1'
    should include_sexp [:cmd,  'source ~/virtualenv/pypy-5.3.1/bin/activate', assert: true, echo: true, timing: true]
    should include_sexp [:cmd,  "curl -sSf -o pypy-5.3.1.tar.bz2 ${archive_url}", echo: true, timing: true]
    should include_sexp [:cmd,  "rm pypy-5.3.1.tar.bz2"]
  end

  it 'sets up the python version (pypy3.3-5.2-alpha1)' do
    data[:config][:python] = 'pypy3.3-5.2-alpha1'
    should include_sexp [:cmd,  'source ~/virtualenv/pypy3.3-5.2-alpha1/bin/activate', assert: true, echo: true, timing: true]
    should include_sexp [:cmd,  "curl -sSf -o pypy3.3-5.2-alpha1.tar.bz2 ${archive_url}", echo: true, timing: true]
    should include_sexp [:cmd,  "rm pypy3.3-5.2-alpha1.tar.bz2"]
  end

  it 'sets up the python version (pypy3)' do
    data[:config][:python] = 'pypy3'
    should include_sexp [:cmd,  "curl -sSf -o pypy3.tar.bz2 ${archive_url}", echo: true, timing: true]
    should include_sexp [:cmd,  'source ~/virtualenv/pypy3/bin/activate', assert: true, echo: true, timing: true]
  end

  it 'sets up the python version (3.6)' do
    should include_sexp [:cmd,  'source ~/virtualenv/python3.6/bin/activate', assert: true, echo: true, timing: true]
  end

  context "with minimal config" do
    before do
      data[:config][:language] = 'python'; data[:config].delete(:python)
      described_class.send :remove_const, :DEPRECATIONS
      described_class.const_set("DEPRECATIONS", [
        {
          name: 'Python',
          current_default: '2.7',
          new_default: '3.5',
          cutoff_date: '2020-01-01',
        }
      ])
    end

    context "before default change cutoff date" do
      before do
        DateTime.stubs(:now).returns(DateTime.parse("2019-12-01"))
      end
      it { store_example name: "update-default-before-cutoff" }
      it { should include_sexp [:echo, /Using the default Python version/, ansi: :yellow] }
    end

    context "after default change cutoff date" do
      before do
        DateTime.stubs(:now).returns(DateTime.parse("2020-02-01"))
      end
      it { should_not include_sexp [:echo, /Using the default Python version/, ansi: :yellow] }
    end
  end


  context "when python version is given as an array" do
    before { data[:config][:python] = %w(3.6) }
    it 'sets up the python version (3.6)' do
      should include_sexp [:cmd,  'source ~/virtualenv/python3.6/bin/activate', assert: true, echo: true, timing: true]
    end
  end

  it 'sets up the python version nightly' do
    data[:config][:python] = 'nightly'
    should include_sexp [:cmd,  'sudo tar xjf python-nightly.tar.bz2 --directory /', echo: true, assert: true, timing: true]
    should include_sexp [:cmd,  'source ~/virtualenv/pythonnightly/bin/activate', assert: true, echo: true, timing: true]
  end

  context 'when specified Python is not pre-installed' do
    let(:version) { '3.6' }
    let(:sexp) { sexp_find(subject, [:if, "! -f ~/virtualenv/python#{version}/bin/activate"]) }

    it "downloads archive" do
      branch = sexp_find(sexp, [:then])
      expect(branch).to include_sexp [:raw, "archive_url=https://s3.amazonaws.com/travis-python-archives/binaries/${travis_host_os}/${travis_rel_version}/$(uname -m)/python-#{version}.tar.bz2"]
    end

    context 'and using a custom archive url' do
      before { ENV["TRAVIS_BUILD_LANG_ARCHIVES_PYTHON"] = "cdn.of.lots.of.python.stuff" }
      after  { ENV.delete("TRAVIS_BUILD_LANG_ARCHIVES_PYTHON") }

      it "downloads archive" do
        ENV['']
        branch = sexp_find(sexp, [:then])
        expect(branch).to include_sexp [:raw, "archive_url=https://cdn.of.lots.of.python.stuff/binaries/${travis_host_os}/${travis_rel_version}/$(uname -m)/python-#{version}.tar.bz2"]
      end
    end

    context 'and using gcs as language archive host' do
      before :each do
        @old_lang_archive_host = Travis::Build.config.lang_archive_host
        Travis::Build.config.lang_archive_host = 'gcs'
      end

      after { Travis::Build.config.lang_archive_host = @old_lang_archive_host }

      it "downloads archive" do
        ENV['']
        branch = sexp_find(sexp, [:then])
        expect(branch).to include_sexp [:raw, "archive_url=https://storage.googleapis.com/travis-ci-language-archives/python/binaries/${travis_host_os}/${travis_rel_version}/$(uname -m)/python-#{version}.tar.bz2"]
      end

      it 'sets up pypy' do
        data[:config][:python] = 'pypy-5.3.1'
        should include_sexp [:raw, "archive_url=https://storage.googleapis.com/travis-ci-language-archives/python/binaries/${travis_host_os}/${travis_rel_version}/$(uname -m)/pypy-5.3.1.tar.bz2"]
      end
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

    it 'adds ${TRAVIS_HOME}/.cache/pip to directory cache' do
      should include_sexp [:cmd, 'rvm $(travis_internal_ruby) --fuzzy do $CASHER_DIR/bin/casher add ${TRAVIS_HOME}/.cache/pip', timing: true]
    end
  end

  it 'sets up python with system site packages enabled' do
    data[:config][:virtualenv] = { 'system_site_packages' => true }
    should include_sexp [:cmd,  'source ~/virtualenv/python3.6_with_system_site_packages/bin/activate', assert: true, echo: true, timing: true]
  end
end
