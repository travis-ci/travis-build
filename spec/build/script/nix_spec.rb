require 'spec_helper'

describe Travis::Build::Script::Nix, :sexp do
  let(:config) { {} }
  let(:data)   { payload_for(:push, :nix, config: config) }
  let(:script) { described_class.new(data) }
  subject      { script.sexp }
  it           { store_example }

  it_behaves_like 'a bash script'

  it 'announces nix-env --version' do
    should include_sexp [:cmd, 'nix-env --version', echo: true]
  end

  it_behaves_like 'a build script sexp'

  context 'when a channel is configured' do
    let(:config) { { channels: { foo: 'bar' } } }
    it 'sets the configured channels' do
      should include_sexp [:cmd, 'nix-channel --add bar foo', assert: true, timing: true, echo: true]
    end
  end

  context 'when the nixpkgs channel is configured' do
    context 'when using a version number shorthand' do
      let(:config) { { channels: { nixpkgs: '18.09' } } }
      it 'sets the nixpkgs channel' do
        should include_sexp [:cmd, 'nix-channel --add https://nixos.org/channels/nixos-18.09 nixpkgs', assert: true, timing: true, echo: true]
      end
    end

    context 'when using a full url' do
      let(:config) { { channels: { nixpkgs: 'https://nixos.org/channels/nixos-18.09' } } }
      it 'sets the nixpkgs channel' do
        should include_sexp [:cmd, 'nix-channel --add https://nixos.org/channels/nixos-18.09 nixpkgs', assert: true, timing: true, echo: true]
      end
    end
  end
end
