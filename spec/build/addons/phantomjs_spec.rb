require 'spec_helper'

describe Travis::Build::Addons::PhantomJs, :sexp do
  let(:script) { stub('script') }
  let(:data)   { payload_for(:push, :ruby, config: { addons: { phantomjs: config } }) }
  let(:sh)     { Travis::Shell::Builder.new }
  let(:addon)  { described_class.new(script, sh, Travis::Build::Data.new(data), config) }
  let(:home)   { Travis::Build::HOME_DIR }
  let(:host)   { 'download.mozilla.org'}
  let(:os)     { 'linux64' }
  subject      { sh.to_sexp }
  before       { addon.after_prepare }

  context 'given a valid version string' do
    let(:config) { '2.0.0' }

    it { store_example }

    it_behaves_like 'compiled script'

    it { should_not include_sexp [:echo, %r"Installing PhantomJS 2.0.0.*"] }
  end

  context 'given a invalid version string' do
    let(:config) { '2.0.0; sudo rm -rf /' }

    it_behaves_like 'compiled script'

    it { should include_sexp [:echo, %r"Invalid version '2.0.0\\;\\ sudo\\ rm\\ -rf\\ /' given.*", ansi: :red] }
    it { should_not include_sexp [:echo, %r"Installing PhantomJS.*", ansi: :yellow] }
  end
end

