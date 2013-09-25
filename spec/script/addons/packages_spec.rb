require "spec_helper"

describe Travis::Build::Script::Addons::Packages do
  let(:script) { stub("script", cmd: nil, if: nil, else: nil) }
  let(:config) {[ "foo", "bar=1" ]}

  subject { described_class.new(script, config) }

  it "checks for an available package manager" do
    script.expects(:if).with("hash brew 2>/dev/null").yields(script)
    subject.before_install
  end

  it "uses brew to install packages for mac builds" do
    if_script = stub("if_script")
    script.expects(:if).yields(if_script)
    if_script.expects(:cmd).with("brew update", assert: true)
    if_script.expects(:cmd).with("brew install foo bar\\=1", assert: true)
    subject.before_install
  end

  it "uses brew to install packages for mac builds" do
    else_script = stub("else_script")
    script.expects(:else).yields(else_script)
    else_script.expects(:cmd).with("sudo apt-get -qq update", assert: true)
    else_script.expects(:cmd).with("sudo apt-get -qq install foo bar\\=1", assert: true)
    subject.before_install
  end
end
