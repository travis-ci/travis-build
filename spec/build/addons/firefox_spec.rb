require 'spec_helper'

describe Travis::Build::Addons::Firefox, :sexp do
  let(:script) { stub('script') }
  let(:data)   { payload_for(:push, :ruby, config: { addons: { firefox: config } }) }
  let(:sh)     { Travis::Shell::Builder.new }
  let(:addon)  { described_class.new(script, sh, Travis::Build::Data.new(data), config) }
  let(:home)   { Travis::Build::HOME_DIR }
  let(:host)   { 'download.mozilla.org'}
  let(:os)     { 'linux64' }
  let(:path)   { "?product=firefox-#{config}&lang=en-US&os=#{os}"}
  subject      { sh.to_sexp }
  before       { addon.after_prepare }

  context 'given a valid version string' do
    let(:config) { '20.0' }

    it { store_example }

    it_behaves_like 'compiled script' do
      let(:code) { ['install_firefox', 'firefox-20.0.tar.bz2'] }
    end

    it { should include_sexp [:echo, 'Installing Firefox 20.0', ansi: :yellow] }
    it { should include_sexp [:mkdir, '$HOME/firefox-20.0', recursive: true] }
    it { should include_sexp [:chown, ['travis', '$HOME/firefox-20.0'], recursive: true] }
    it { should include_sexp [:cd, '$HOME/firefox-20.0', stack: true] }
    it { should include_sexp [:export, ['FIREFOX_SOURCE_URL', "'https://#{host}/#{path}'"], echo: true] }

    it { should include_sexp [:cmd, 'wget -O /tmp/firefox-20.0.tar.bz2 $FIREFOX_SOURCE_URL', echo: true, timing: true, retry: true] }
    it { should include_sexp [:cmd, 'tar xf /tmp/firefox-20.0.tar.bz2'] }
    it { should include_sexp [:export, ['PATH', "$HOME/firefox-20.0/firefox:$PATH"], echo: true] }
    it { should include_sexp [:cd, :back, stack: true] }
  end

  context 'given a valid version "50.0b6"' do
    let(:config) { '50.0b6' }
    it { should include_sexp [:export, ['PATH', "$HOME/firefox-50.0b6/firefox:$PATH"], echo: true] }
  end

  context 'given a valid version "latest"' do
    let(:config) { 'latest' }
    it { should include_sexp [:export, ['PATH', "$HOME/firefox-latest/firefox:$PATH"], echo: true] }
    it "exports correct FIREFOX_SOURCE_URL for the Mac" do
      expect(sexp_find(subject, [:if, "$(uname) = 'Linux'"], [:else])).to include_sexp(
        [:export, ['FIREFOX_SOURCE_URL', "\'https://#{host}/?product=firefox-latest&lang=en-US&os=osx'"], echo: true]
      )
    end
  end

  context 'given a valid version "latest-beta"' do
    let(:config) { 'latest-beta' }
    it { should include_sexp [:export, ['PATH', "$HOME/firefox-latest-beta/firefox:$PATH"], echo: true] }
  end

  context 'given a valid version "latest-esr"' do
    let(:config) { 'latest-esr' }
    it { should include_sexp [:export, ['PATH', "$HOME/firefox-latest-esr/firefox:$PATH"], echo: true] }
  end

  context 'given a valid version "latest-unsigned"' do
    let(:config) { 'latest-unsigned' }
    it "exports latest-unsigned source URL" do
      expect(sexp_find(subject, [:if, "$(uname) = 'Linux'"])).to include_sexp(
        [:export, ['FIREFOX_SOURCE_URL', "\"https://index.taskcluster.net/v1/task/gecko.v2.mozilla-release.latest.firefox.linux64-add-on-devel/artifacts/public/build/firefox-$(curl -sfL https://index.taskcluster.net/v1/task/gecko.v2.mozilla-release.latest.firefox.linux64-add-on-devel/artifacts/public/build/buildbot_properties.json | jq -r .properties.appVersion).en-US.linux-x86_64-add-on-devel.tar.bz2\""], echo: true]
      )
    end
    it { should include_sexp [:export, ['PATH', "$HOME/firefox-latest-unsigned/firefox:$PATH"], echo: true] }
  end

  context 'given a invalid version string' do
    let(:config) { '20.0; sudo rm -rf /' }

    it_behaves_like 'compiled script' do
      let(:code) { ['install_firefox', 'Invalid version'] }
    end

    it { should include_sexp [:echo, "Invalid version '20.0\\;\\ sudo\\ rm\\ -rf\\ /' given.", ansi: :red] }
    it { should_not include_sexp [:export, ['PATH', "$HOME/firefox-20.0/firefox:$PATH"], echo: true] }
  end
end

