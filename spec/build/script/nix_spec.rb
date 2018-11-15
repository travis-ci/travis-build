require 'spec_helper'

describe Travis::Build::Script::Nix, :sexp do
  let(:data)   { payload_for(:push, :nix) }
  let(:script) { described_class.new(data) }
  subject      { script.sexp }
  it           { store_example }

  it_behaves_like 'a bash script'

  it 'announces nix-env --version' do
    should include_sexp [:cmd, 'nix-env --version', echo: true]
  end
end
