require 'spec_helper'

describe Travis::Build::Script::Addons::Firefox, :sexp do
  let(:config)  { '20.0' }
  let(:data)    { { config: { addons: { firefox: config } } } }
  let(:sh)      { Travis::Shell::Builder.new }
  let(:addon)   { described_class.new(sh, Travis::Build::Data.new(data), config) }
  subject       { sh.to_sexp }
  before        { addon.before_prepare }

  it_behaves_like 'compiled script' do
    let(:code) { ['install_firefox', 'firefox.tar.bz2'] }
  end

  it { should include_sexp [:echo, 'Installing Firefox v20.0', ansi: :yellow] }
  it { should include_sexp [:mkdir, '/usr/local/firefox-20.0', recursive: true, sudo: true] }
  it { should include_sexp [:chown, ['travis', '/usr/local/firefox-20.0'], recursive: true, sudo: true] }
  it { should include_sexp [:cmd, 'wget -O /tmp/firefox.tar.bz2 http://releases.mozilla.org/pub/firefox/releases/20.0/linux-x86_64/en-US/firefox-20.0.tar.bz2', retry: true] }
  it { should include_sexp [:cd, '/usr/local/firefox-20.0', stack: true] }
  it { should include_sexp [:cmd, 'tar xf /tmp/firefox.tar.bz2'] }
  it { should include_sexp [:cd, :back, stack: true] }
  it { should include_sexp [:cmd, 'ln -sf /usr/local/firefox-20.0/firefox/firefox /usr/local/bin/firefox', sudo: true] }
  it { should include_sexp [:cmd, 'ln -sf /usr/local/firefox-20.0/firefox/firefox-bin /usr/local/bin/firefox-bin', sudo: true] }
end

