require 'spec_helper'

describe Travis::Build::Addons::TensorFlow, :sexp do
  let(:script) { stub('script') }
  let(:config) { '10.0' }
  let(:data)   { payload_for(:push, :ruby, config: { addons: { tensor_flow: config } }) }
  let(:sh)     { Travis::Shell::Builder.new }
  let(:addon)  { described_class.new(script, sh, Travis::Build::Data.new(data), config) }
  subject      { sh.to_sexp }
  before       { addon.after_prepare }

  context 'when version is invalid' do
    let(:config) { '2.112323' }

    it do
      should include_sexp [:echo, "Invalid version '2.112323' given. Valid versions are: 0.12.1 1.0.0 1.0.1 1.1.0 1.2.0 1.2.1 1.3.0 1.4.0 1.4.1 1.5.0 1.5.1 1.6.0 1.7.0 1.7.1 1.8.0 1.9.0 1.10.0 1.10.1 1.11.0 1.12.0 1.12.2 1.12.3 1.13.1 1.13.2 1.14.0 1.15.0 1.15.2 1.15.31.15.4 1.15.5 2.0.0 2.0.1 2.0.2 2.0.3 2.0.4 2.1.0 2.1.1 2.1.2 2.1.3 2.1.4 2.2.0 2.2.1 2.2.2 2.2.3 2.3.0 2.3.1 2.3.2 2.3.3 2.3.4 2.4.0 2.4.1 2.4.2 2.4.3 2.4.4 2.5.0 2.5.1 2.5.2 2.6.0rc0 2.6.0rc1 2.6.0rc2 2.6.0 2.6.1 2.6.2", { ansi: :red }]    end
  end

  context 'when version is valid' do
    let(:config) { '2.6.0' }

    it { should include_sexp [:echo, 'Installing TensorFlow version: 2.6.0', { ansi: :yellow }] }
    it { should include_sexp [:cmd, "pip install tensorflow==2.6.0"] }
  end
end
