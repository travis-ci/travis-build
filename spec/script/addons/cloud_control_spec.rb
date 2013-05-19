require 'spec_helper'

describe Travis::Build::Script::Addons::CloudControl do
  let(:config) {{ api_key: 'mykey' }}
  let(:script) { stub('script') }
  subject { described_class.new(script, config) }

  it 'runs the command' do
    script.expects(:if).with("($TRAVIS_PULL_REQUEST = false) && ($TRAVIS_BRANCH = master)").yields(script)

    script.expects(:fold).with("cctrl.1").yields(script)
    script.expects(:cmd).with("echo -e \"\\033[33;1mInstalling tools for cloudControl deploy\\033[0m\"", assert: false, echo: false)
    script.expects(:cmd).with('pip install cctrl', assert: true, echo: true)

    script.expects(:fold).with("cctrl.2").yields(script)
    script.expects(:cmd).with("echo -e \"\\033[33;1mDeploying to cloudControl\\033[0m\"", assert: false, echo: false)
    script.expects(:cmd).with("mkdir ~/.cloudControl", assert: true, echo: false)
    script.expects(:cmd).with('echo \'{"token": "mykey"}\' > ~/.cloudControl/token.json', assert: true, echo: false)
    script.expects(:cmd).with('cctrlapp $(basename $(pwd)) push', assert: true, echo: true)

    subject.after_success
  end
end
