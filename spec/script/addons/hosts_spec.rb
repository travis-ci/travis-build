require "spec_helper"

describe Travis::Build::Script::Addons::Hosts do
  let(:script) { stub_everything("script") }
  let(:config) { "johndoe.local" }

  before(:each) { script.stubs(:fold).yields(script) }

  subject { described_class.new(script, config).setup }

  it "runs the commands" do
    script.expects(:fold).with("hosts").yields(script)
    script.expects(:cmd).with("sudo sed -e 's/^\\(127\\.0\\.0\\.1.*\\)$/\\1 #{config}/' -i'.bak' /etc/hosts")
    script.expects(:cmd).with("sudo sed -e 's/^\\(::1.*\\)$/\\1 #{config}/' -i'.bak' /etc/hosts")
    subject
  end

  context "multiple hostnames" do
    let(:config) { %w[johndoe.local example.local] }

    it "runs the command" do
      script.expects(:fold).with("hosts").yields(script)
      script.expects(:cmd).with("sudo sed -e 's/^\\(127\\.0\\.0\\.1.*\\)$/\\1 johndoe.local example.local/' -i'.bak' /etc/hosts")
      script.expects(:cmd).with("sudo sed -e 's/^\\(::1.*\\)$/\\1 johndoe.local example.local/' -i'.bak' /etc/hosts")

      subject
    end
  end
end
