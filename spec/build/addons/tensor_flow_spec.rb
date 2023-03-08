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
      should include_sexp [:echo, "Invalid version '2.112323' given. Valid versions are: 2.11, 1.15", { ansi: :red }]
    end
  end

  context 'when version is valid' do
    let(:config) { '2.11' }

    it { should include_sexp [:echo, 'Installing TenserFlow version: 2.11', { ansi: :yellow }] }
    it { should include_sexp [:cmd, "pip install --trusted-host pip.cache.staging.travis-ci.com -i http://pip.cache.staging.travis-ci.com/root/pypi/+simple/ 'tensorflow==2.11' --force-reinstall"] }
  end
end
