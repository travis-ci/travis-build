require 'spec_helper'

describe Travis::Build::Addons::Chrome, :sexp do
  let(:script) { stub('script') }
  let(:data)   { payload_for(:push, :ruby, config: { addons: { chrome: version } }) }
  let(:sh)     { Travis::Shell::Builder.new }
  let(:addon)  { described_class.new(script, sh, Travis::Build::Data.new(data), version) }
  subject      { sh.to_sexp }
  before       { addon.after_prepare }

  context 'given a valid version string' do
    let(:version) { 'stable' }

    it { store_example }

    it_behaves_like 'compiled script' do
      let(:code) { ['install_chrome', 'stable'] }
    end

    it { should include_sexp [:echo, 'Installing Google Chrome stable', ansi: :yellow] }
    it { should include_sexp [:export, ['CHROME_SOURCE_URL', "https://dl.google.com/dl/linux/direct/google-chrome-stable_current_amd64.deb"], echo: true] }
  end

  context 'given a valid version "beta"' do
    let(:version) { 'beta' }
    it { should include_sexp [:export, ['CHROME_SOURCE_URL', "https://dl.google.com/dl/linux/direct/google-chrome-beta_current_amd64.deb"], echo: true] }
  end

  context 'given a invalid version string' do
    let(:version) { '20.0; sudo rm -rf /' }

    it_behaves_like 'compiled script' do
      let(:code) { ['install_chrome', 'Invalid version'] }
    end

    it { should include_sexp [:echo, "Invalid version '20.0\\;\\ sudo\\ rm\\ -rf\\ /' given.", ansi: :red] }
    it { should_not include_sexp [:export, ['CHROME_SOURCE_URL', "https://dl.google.com/dl/linux/direct/google-chrome-stable_current_amd64.deb"], echo: true] }
  end
end

