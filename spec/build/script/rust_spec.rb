require 'spec_helper'

describe Travis::Build::Script::Rust, :sexp do
  let(:data)   { payload_for(:push, :rust, config: config) }
  let(:config) { {} }
  let(:script) { described_class.new(data) }
  subject      { script.sexp }
  it           { store_example }

  it_behaves_like 'compiled script' do
    let(:code) { ['TRAVIS_LANGUAGE=rust'] }
    let(:cmds) { ['cargo build --verbose'] }
  end

  it_behaves_like 'a build script sexp'

  it 'downloads and installs Rust' do
    should include_sexp [:cmd, %r(curl .*rustup.sh), assert: true, echo: true, timing: true]
  end

  it 'announces rust version' do
    should include_sexp [:cmd, 'rustc --version', echo: true]
  end

  it 'announces cargo version' do
    should include_sexp [:cmd, 'cargo --version', echo: true]
  end

  it 'runs cargo test' do
    should include_sexp [:cmd, 'cargo test --verbose', echo: true, timing: true]
  end

  it 'runs cargo build' do
    should include_sexp [:cmd, 'cargo build --verbose', echo: true, timing: true]
  end

  it 'runs cargo test' do
    should include_sexp [:cmd, 'cargo test --verbose', echo: true, timing: true]
  end

  context "when cache is configured" do
    let(:options) { { fetch_timeout: 20, push_timeout: 30, type: 's3', s3: { bucket: 's3_bucket', secret_access_key: 's3_secret_access_key', access_key_id: 's3_access_key_id' } } }
    let(:data)   { payload_for(:push, :rust, config: { cache: 'cargo' }, cache_options: options) }

    it 'caches desired directories' do
      should include_sexp [:cmd, 'rvm $(travis_internal_ruby) --fuzzy do $CASHER_DIR/bin/casher add $HOME/.cargo target', timing: true]
    end
  end
end
