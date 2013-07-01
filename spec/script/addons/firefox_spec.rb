require 'spec_helper'

describe Travis::Build::Script::Addons::Firefox do
  let(:script) { stub_everything('script') }

  before(:each) { script.stubs(:fold).yields(script) }

  subject { described_class.new(script, config).before_install }

  let(:config) { '20.0' }

  it 'runs the command' do
    script.expects(:fold).with('install_firefox').yields(script)
    script.expects(:cmd).with("echo -e \"\033[33;1mInstalling Firefox v20.0\033[0m\"; ", assert: false, echo: false)
    script.expects(:cmd).with("sudo mkdir -p /usr/local/firefox/20.0", assert: false)
    script.expects(:cmd).with("sudo chown -R travis /usr/local/firefox", assert: false)
    script.expects(:cmd).with("wget -O /tmp/firefox.tar.bz2 http://ftp.mozilla.org/pub/firefox/releases/20.0/linux-x86_64/en-US/firefox-20.0.tar.bz2", assert: false)
    script.expects(:cmd).with("pushd /usr/local/firefox/20.0", assert: false)
    script.expects(:cmd).with("tar xf /tmp/firefox.tar.bz2", assert: false)
    script.expects(:cmd).with("sudo ln -sf /usr/local/firefox/20.0/firefox/firefox /usr/local/bin/firefox", assert: false)
    script.expects(:cmd).with("sudo ln -sf /usr/local/firefox/20.0/firefox/firefox-bin /usr/local/bin/firefox-bin", assert: false)
    script.expects(:cmd).with("popd", assert: false)
    subject
  end
end
