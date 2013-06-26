require 'spec_helper'

describe Travis::Build::Script::Addons::Deploy do
  let(:config) {{ provider: "heroku", password: 'foo', email: 'user@host' }}
  let(:script) { stub('script') }
  subject { described_class.new(script, config) }

  it 'runs the command' do
    script.expects(:if).with('($TRAVIS_PULL_REQUEST = false) && ($TRAVIS_BRANCH = master)').yields(script)
    script.expects(:cmd).with('gem install dpl', assert: true, echo: false)
    script.expects(:cmd).with('dpl --provider="heroku" --password="foo" --email="user@host" --fold', assert: true, echo: false)
    subject.after_success
  end
end
