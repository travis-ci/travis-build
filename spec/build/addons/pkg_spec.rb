require "spec_helper"

describe Travis::Build::Addons::Pkg, :sexp do
  let(:script) { stub('script') }
  #let(:pkg_config) { ['travis', { name: 'aws-cli', no_deps: true }] }
  let(:pkg_config) { {} }
  let(:data)   { payload_for(:push, :ruby, config: { os: 'freebsd', addons: { pkg: pkg_config } }) }
  let(:sh)     { Travis::Shell::Builder.new }
  let(:addon)  { described_class.new(script, sh, Travis::Build::Data.new(data), pkg_config) }
  subject      { sh.to_sexp }
  before       { addon.before_prepare }

  context 'when on linux' do
    let(:data) { payload_for(:push, :ruby, config: { os: 'linux' }) }

    it 'will not run' do
      expect(addon.before_prepare?).to eql false
    end
  end

  context 'when on freebsd' do
    let(:data) { payload_for(:push, :ruby, config: { os: 'freebsd' }) }

    it 'will run' do
      expect(addon.before_prepare?).to eql true
    end
  end

  context 'with multiple packages' do
    let(:pkg_config) { { packages: ['git', 'curl'] } }

    it { should include_sexp [:cmd, "su -m root -c 'pkg install git curl'", echo: true, timing: true, assert: true] }
  end

  context 'with single packages' do
    let(:pkg_config) { { packages: ['git'] } }

    it { should include_sexp [:cmd, "su -m root -c 'pkg install git'", echo: true, timing: true, assert: true] }
  end
end
