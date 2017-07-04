require 'spec_helper'

describe Travis::Build::Script::Idris, :sexp do
  let(:data)   { payload_for(:push, :idris) }
  let(:script) { described_class.new(data) }
  subject      { script.sexp }
  it           { store_example }

  it_behaves_like 'a build script sexp'

  it 'sets TRAVIS_IDRIS_VERSION' do
    should include_sexp [:export, ['TRAVIS_IDRIS_VERSION', '1.0']]
  end

  it 'downloads and installs Idris' do
    should include_sexp [:cmd, %r(stack install --install-ghc idris-1.0), assert: true, echo: true, timing: true]
  end

  it 'announces idris version' do
    should include_sexp [:cmd, 'idris --version', echo: true]
  end

  context "when cache is configured" do
    let(:options) { { fetch_timeout: 20, push_timeout: 30, type: 's3', s3: { bucket: 's3_bucket', secret_access_key: 's3_secret_access_key', access_key_id: 's3_access_key_id' } } }
    let(:data)   { payload_for(:push, :rust, config: { cache: 'idris' }, cache_options: options) }

    it 'caches desired directories' do
      should include_sexp [:cmd, 'rvm $(travis_internal_ruby) --fuzzy do $CASHER_DIR/bin/casher add $HOME/.stack', timing: true]
    end
  end
end
