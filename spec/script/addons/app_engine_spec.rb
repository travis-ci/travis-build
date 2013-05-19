require 'spec_helper'

describe Travis::Build::Script::Addons::AppEngine do
  let(:config) {{ password: 'foo', email: 'user@host' }}
  let(:script) { stub('script') }
  subject { described_class.new(script, config) }

  it 'runs the command' do
    script.expects(:if).with("($TRAVIS_PULL_REQUEST = false) && ($TRAVIS_BRANCH = master)").yields(script)

    script.expects(:fold).with("app_engine.1").yields(script)
    script.expects(:cmd).with("echo -e \"\\033[33;1mInstalling tools for App Engine deploy\\033[0m\"", assert: false, echo: false)
    script.expects(:cmd).with('curl -o ~/gae.zip "https://googleappengine.googlecode.com/files/google_appengine_1.8.0.zip"', assert: true, echo: true)
    script.expects(:cmd).with('unzip -q -d ~ ~/gae.zip', assert: true, echo: true)

    script.expects(:fold).with("app_engine.2").yields(script)
    script.expects(:cmd).with("echo -e \"\\033[33;1mDeploying to App Engine\\033[0m\"", assert: false, echo: false)
    script.expects(:cmd).with('echo foo | ~/google-appengine/appcfg.py update --email=user@host --passin .', assert: true, echo: false)

    subject.after_success
  end
end
