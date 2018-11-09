require 'spec_helper'

describe Travis::Build::Addons::AptRetries, :sexp do
  let(:script) { stub('script') }
  let(:data)   { payload_for(:push, :ruby, config: { addons: { apt_retries: config } }) }
  let(:sh)     { Travis::Shell::Builder.new }
  let(:addon)  { described_class.new(script, sh, Travis::Build::Data.new(data), config) }

  subject { sh.to_sexp }
  before { addon.before_configure }

  context "when apt_retries is set" do
    let(:config) { 'true' }

    it { store_example }
    it { should include_sexp [:echo, "Configuring default apt-get retries", ansi: :yellow] }
  end
end
