require 'spec_helper'

describe Travis::Build::Script::Addons::MariaDB do
  let(:script) { stub_everything('script') }

  before(:each) { script.stubs(:fold).yields(script) }

  subject { described_class.new(script, config).after_pre_setup }

  let(:config) { '10.0' }

  it 'runs the command' do
    script.expects(:fold).with('mariadb').yields(script)
    script.expects(:echo).with("Starting MariaDB v#{config}", ansi: :yellow)
    script.expects(:cmd).with("sudo apt-get install -o Dpkg::Options::='--force-confnew' mariadb-server")
    subject
  end
end
