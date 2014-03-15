require 'spec_helper'

describe Travis::Build::Script::Addons::Postgresql do
  let(:script) { stub_everything('script') }
  let(:bin_path) { Travis::Build::Script::Addons::BIN_PATH }

  before(:each) { script.stubs(:fold).yields(script) }

  subject { described_class.new(script, config).before_install }

  let(:config) { '9.3' }

  it 'runs the command' do
    script.expects(:fold).with('postgresql').yields(script)
    script.expects(:cmd).with("sudo #{bin_path}/travis-addon-postgresql 9.3", assert: true, echo: false, log: false)
    subject
  end
end
