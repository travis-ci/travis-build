require 'spec_helper'

describe Travis::Build::Script::Addons::Postgresql do
  let(:script) { stub_everything('script') }

  before(:each) { script.stubs(:fold).yields(script) }

  subject { described_class.new(script, config).before_install }

  let(:config) { '9.3' }

  it 'runs the command' do
    script.expects(:fold).with('postgresql').yields(script)
    script.expects(:cmd).with("echo -e \"\033[33;1mStart PostgreSQL v9.3\033[0m\"; ", assert: false, echo: false)
    script.expects(:cmd).with("sudo service postgresql stop", assert: false)
    script.expects(:cmd).with("sudo service postgresql start 9.3", assert: false)
    subject
  end
end
