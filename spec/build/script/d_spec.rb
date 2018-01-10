require 'spec_helper'

describe Travis::Build::Script::D, :sexp do
  let(:data)   { payload_for(:push, :d) }
  let(:script) { described_class.new(data) }
  subject      { script.sexp }
  it           { store_example }

  after(:all) do
    #store_example
  end

  it_behaves_like 'a build script sexp'

  it 'downloads and runs the installer script' do
    should include_sexp [:cmd, %r{https://dlang\.org/install\.sh},
                         assert: true, echo: true, timing: true]
    should include_sexp [:cmd, %r{https://downloads\.dlang\.org/other/install\.sh},
                         assert: true, echo: true, timing: true]
    should include_sexp [:cmd, %r{https://nightlies\.dlang\.org/install\.sh},
                         assert: true, echo: true, timing: true]
    should include_sexp [:cmd, %r{https://github\.com/dlang/installer/raw/stable/script/install\.sh},
                         assert: true, echo: true, timing: true]
    should include_sexp [:cmd, %r{source.*bash.*install\.sh.*--activate},
                         assert: true, echo: true, timing: true]
  end

  it 'announces compiler version' do
    should include_sexp [:cmd, '$DC --version', echo: true]
  end

  it 'announces dub' do
    should include_sexp [:cmd, 'dub --help | tail -n 1', echo: true]
  end

  it 'runs dub test with DC' do
    should include_sexp [:cmd, 'dub test --compiler=$DC', echo: true, timing: true]
  end

  context 'when an old dmd version is configured' do
    before do
      data[:config][:d] = 'dmd-2.066.0'
    end

    it 'announces compiler version' do
      should include_sexp [:cmd, 'dmd --help | head -n 2', echo: true]
    end
  end

  context 'when a compiler is configured' do
    before do
      data[:config][:d] = 'ldc-0.17.1'
    end

    it 'passed the compiler to the install script' do
      should include_sexp [:cmd, %r{source.*bash.*install\.sh.*ldc-0.17.1.*--activate},
                           assert: true, echo: true, timing: true]
    end
  end

  context 'when cache is configured' do
    let(:options) { { fetch_timeout: 20, push_timeout: 30, type: 's3', s3: { bucket: 's3_bucket', secret_access_key: 's3_secret_access_key', access_key_id: 's3_access_key_id' } } }
    let(:data)   { payload_for(:push, :d, config: { cache: 'dub' }, cache_options: options) }

    it 'caches desired directories' do
      should include_sexp [:cmd, 'rvm $(travis_internal_ruby) --fuzzy do $CASHER_DIR/bin/casher add $HOME/.dub $HOME/dlang', timing: true]
    end
  end

end
