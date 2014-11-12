require 'spec_helper'

describe Travis::Build::Addons::Firefox, :sexp do
  let(:script) { stub('script') }
  let(:config) { '20.0' }
  let(:data)   { payload_for(:push, :ruby, config: { addons: { firefox: config } }) }
  let(:sh)     { Travis::Shell::Builder.new }
  let(:addon)  { described_class.new(script, sh, Travis::Build::Data.new(data), config) }
  let(:home)   { Travis::Build::HOME_DIR }
  subject      { sh.to_sexp }
  before       { addon.before_setup }

  it_behaves_like 'compiled script' do
    let(:code) { ['install_firefox', 'firefox.tar.bz2'] }
  end

  # it { should include_sexp [:echo, 'Installing Firefox v20.0', ansi: :yellow] }
  # it { should include_sexp [:mkdir, '/usr/local/firefox-20.0', recursive: true, sudo: true] }
  # it { should include_sexp [:chown, ['travis', '/usr/local/firefox-20.0'], recursive: true, sudo: true] }
  # it { should include_sexp [:cmd, 'wget -O /tmp/firefox.tar.bz2 http://releases.mozilla.org/pub/firefox/releases/20.0/linux-x86_64/en-US/firefox-20.0.tar.bz2', retry: true] }
  # it { should include_sexp [:cd, '/usr/local/firefox-20.0', stack: true] }
  # it { should include_sexp [:cmd, 'tar xf /tmp/firefox.tar.bz2'] }
  # it { should include_sexp [:cd, :back, stack: true] }
  # it { should include_sexp [:cmd, 'ln -sf /usr/local/firefox-20.0/firefox/firefox /usr/local/bin/firefox', sudo: true] }
  # it { should include_sexp [:cmd, 'ln -sf /usr/local/firefox-20.0/firefox/firefox-bin /usr/local/bin/firefox-bin', sudo: true] }

  it { should include_sexp [:echo, 'Installing Firefox v20.0', ansi: :yellow] }
  it { should include_sexp [:raw, "mkdir -p #{home}/firefox-20.0"] }
  it { should include_sexp [:raw, "chown -R travis #{home}/firefox-20.0"] }
  it { should include_sexp [:cmd, 'wget -O /tmp/firefox.tar.bz2 http://releases.mozilla.org/pub/firefox/releases/20.0/linux-x86_64/en-US/firefox-20.0.tar.bz2', assert: true, echo: true, timing: true, retry: true] }
  it { should include_sexp [:raw, "pushd #{home}/firefox-20.0"] }
  it { should include_sexp [:raw, 'tar xf /tmp/firefox.tar.bz2'] }
  it { should include_sexp [:raw, "export PATH=#{home}/firefox-20.0/firefox:$PATH"] }
  it { should include_sexp [:raw, 'popd'] }
end

