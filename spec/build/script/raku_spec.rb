require 'spec_helper'

describe Travis::Build::Script::Raku, :sexp do
  let(:data)   { payload_for(:push, :raku) }
  let(:script) { described_class.new(data) }
  subject      { script.sexp }
  it           { store_example }

  it_behaves_like 'a bash script'

  it_behaves_like 'compiled script' do
    let(:code) { ['TRAVIS_LANGUAGE=raku'] }
  end

  it_behaves_like 'a build script sexp'

  it 'announces raku --version' do
    should include_sexp [:cmd, 'raku --version', echo: true]
  end

end
