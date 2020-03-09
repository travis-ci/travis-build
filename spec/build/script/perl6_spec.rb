require 'spec_helper'

describe Travis::Build::Script::Perl6, :sexp do
  let(:data)   { payload_for(:push, :perl6) }
  let(:script) { described_class.new(data) }
  subject      { script.sexp }
  it           { store_example }

  it_behaves_like 'a bash script'

  it_behaves_like 'compiled script' do
    let(:code) { ['TRAVIS_LANGUAGE=perl6'] }
  end

  it_behaves_like 'a build script sexp'

  it 'announces perl6 --version' do
    should include_sexp [:cmd, 'perl6 --version', echo: true]
  end

end
