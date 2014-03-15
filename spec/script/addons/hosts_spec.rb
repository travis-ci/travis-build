require "spec_helper"

describe Travis::Build::Script::Addons::Hosts do
  let(:script) { stub_everything("script") }
  let(:config) { "johndoe.local" }
  let(:bin_path) { Travis::Build::Script::Addons::BIN_PATH }

  before(:each) { script.stubs(:fold).yields(script) }

  subject { described_class.new(script, config).setup }

  it "runs the commands" do
    script.expects(:fold).with("hosts").yields(script)
    script.expects(:cmd).with("sudo #{bin_path}/travis-addon-hosts #{config}", assert: true, log: false, echo: false)
    subject
  end

  context "multiple hostnames" do
    let(:config) { %w[johndoe.local example.local] }

    it "runs the command" do
      script.expects(:fold).with("hosts").yields(script)
      script.expects(:cmd).with("sudo #{bin_path}/travis-addon-hosts johndoe.local example.local", assert: true, log: false, echo: false)
      subject
    end
  end
end
