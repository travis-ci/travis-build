require 'spec_helper'

describe Travis::Build::Script::Addons::Firefox do
  let(:script) { stub_everything('script') }
  let(:bin_path) { Travis::Build::Script::Addons::BIN_PATH }

  before(:each) { script.stubs(:fold).yields(script) }

  subject { described_class.new(script, config).before_install }

  let(:config) { '20.0' }

  it 'runs the command' do
    script.expects(:fold).with('install_firefox').yields(script)
    script.expects(:cmd).with("sudo #{bin_path}/travis-firefox 20.0", assert: true, echo: false)
    subject
  end
end
