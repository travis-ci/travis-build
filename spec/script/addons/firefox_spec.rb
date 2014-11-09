require 'spec_helper'

describe Travis::Build::Script::Addons::Firefox do
  let(:script) { stub_everything('script') }

  before(:each) { script.stubs(:fold).yields(script) }

  subject { described_class.new(script, config).before_install }

  let(:config) { '20.0' }

  it 'runs the command' do
    script.expects(:fold).with('install_firefox').yields(script)
    script.expects(:echo).with("Installing Firefox v#{config}", ansi: :yellow)
    script.expects(:raw).with("mkdir -p #{Travis::Build::HOME_DIR}/firefox-#{config}")
    script.expects(:raw).with("chown -R travis #{Travis::Build::HOME_DIR}/firefox-#{config}")
    script.expects(:cmd).with("wget -O /tmp/firefox.tar.bz2 http://releases.mozilla.org/pub/firefox/releases/#{config}/linux-x86_64/en-US/firefox-#{config}.tar.bz2", retry: true)
    script.expects(:raw).with("pushd #{Travis::Build::HOME_DIR}/firefox-#{config}")
    script.expects(:raw).with("tar xf /tmp/firefox.tar.bz2")
    script.expects(:raw).with("export PATH=#{Travis::Build::HOME_DIR}/firefox-#{config}/firefox:$PATH")
    script.expects(:raw).with("popd")
    subject
  end
end
