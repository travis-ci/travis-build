require 'spec_helper'

describe Travis::Build::Script::Addons::Deploy do
  let(:script) { stub('script') }

  before(:each) { script.stubs(:fold).yields(script) }
  subject { described_class.new(script, config) }

  describe 'minimal config' do
    let(:config) {{ provider: "heroku", password: 'foo', email: 'user@host' }}

    it 'runs the command' do
      script.expects(:if).with('($TRAVIS_PULL_REQUEST = false) && ($TRAVIS_BRANCH = master)').yields(script)
      script.expects(:cmd).with('gem install dpl', assert: true, echo: false)
      script.expects(:cmd).with(<<-DPL.gsub(/\s+/, ' ').strip, assert: false, echo: false)
        dpl --provider="heroku" --password="foo" --email="user@host" --fold ||
        (echo "failed to deploy"; travis_terminate 2)
      DPL
      subject.after_success
    end
  end


  describe 'implicit branches' do
    let(:config) {{ provider: "heroku", app: { staging: "foo", production: "bar" } }}

    before do
      script.stubs(:data).returns(stub('data', branch: 'staging'))
    end

    it 'runs the command' do
      script.expects(:if).with('($TRAVIS_PULL_REQUEST = false) && ($TRAVIS_BRANCH = staging || $TRAVIS_BRANCH = production)').yields(script)
      script.expects(:cmd).with('gem install dpl', assert: true, echo: false)
      script.expects(:cmd).with(<<-DPL.gsub(/\s+/, ' ').strip, assert: false, echo: false)
        dpl --provider="heroku" --app="foo" --fold ||
        (echo "failed to deploy"; travis_terminate 2)
      DPL
      subject.after_success
    end
  end

  describe 'on tags' do
    let(:config) {{ provider: "heroku", on: { tags: true } }}

    it 'runs the command' do
      script.expects(:if).with('($TRAVIS_PULL_REQUEST = false) && ($TRAVIS_BRANCH = master) && ($(git describe --exact-match))').yields(script)
      script.expects(:cmd).with('gem install dpl', assert: true, echo: false)
      script.expects(:cmd).with(<<-DPL.gsub(/\s+/, ' ').strip, assert: false, echo: false)
        dpl --provider="heroku" --fold ||
        (echo "failed to deploy"; travis_terminate 2)
      DPL
      subject.after_success
    end
  end
end
