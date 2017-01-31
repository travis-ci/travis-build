require 'faraday'
require 'json'

describe Travis::Build::Addons::Brew, :sexp do
  let(:script)             { stub('script') }
  let(:data)               { payload_for(:push, :ruby, config: { os: os, addons: { brew: brew_config } }, paranoid: paranoid) }
  let(:sh)                 { Travis::Shell::Builder.new }
  let(:addon)              { described_class.new(script, sh, Travis::Build::Data.new(data), brew_config) }
  let(:brew_config)        { {} }
  let(:os)                 { 'osx' }
  let(:paranoid)           { true }
  subject                  { sh.to_sexp }

  before :all do
    Faraday.default_adapter = :test
  end

  context 'when on linux' do
    let(:data) { payload_for(:push, :ruby, config: { os: 'linux' }) }

    it 'will not run' do
      expect(addon.before_prepare?).to eql(false)
    end
  end

  context 'when on osx' do
    it 'will run' do
      expect(addon.before_prepare?).to eql(true)
    end

    context 'with packages' do
      before :each do
        addon.before_prepare
      end

      let(:brew_config) { { packages: %w( ack automake ) } }

      it { should include_sexp [:cmd, "brew install ack automake", echo: true, timing: true]}
    end
  end
end