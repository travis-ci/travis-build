require 'spec_helper'

describe Travis::Build::Script::Addons::Deploy do
  let(:script) { stub('script') }

  before(:each) { script.stubs(:fold).yields(script) }
  subject { described_class.new(script, config) }

  describe 'minimal config' do
    let(:config) {{ provider: "heroku", password: 'foo', email: 'user@host' }}

    it 'runs the command' do
      script.expects(:run_stage).with(:before_deploy)
      script.expects(:if).with(' ! $TRAVIS_PULL_REQUEST = false').yields(script)
      script.expects(:if).with(' ! $TRAVIS_BRANCH = master').yields(script)
      script.expects(:if).with('($TRAVIS_PULL_REQUEST = false) && ($TRAVIS_BRANCH = master)').yields(script)
      script.expects(:cmd).with('rvm 1.9.3 --fuzzy do ruby -S gem install dpl', assert: true, echo: false)
      script.expects(:cmd).with(<<-DPL.gsub(/\s+/, ' ').strip, assert: false, echo: false)
        rvm 1.9.3 --fuzzy do ruby -S dpl --provider="heroku" --password="foo" --email="user@host" --fold;
        if [ $? -ne 0 ]; then echo "failed to deploy"; travis_terminate 2; fi
      DPL
      script.expects(:cmd).with("echo -e \"\e[33;1mSkipping deployment with the heroku provider because the current build is a pull request.\e[0m\"", {:echo => false, :assert => false, :fold => 'deployment'})
      script.expects(:cmd).with("echo -e \"\e[33;1mSkipping deployment with the heroku provider because this branch is not permitted to deploy.\e[0m\"", {:echo => false, :assert => false, :fold => 'deployment'})
      script.expects(:run_stage).with(:after_deploy)
      subject.deploy
    end
  end


  describe 'implicit branches' do
    let(:config) {{ provider: "heroku", app: { staging: "foo", production: "bar" } }}

    before do
      script.stubs(:data).returns(stub('data', branch: 'staging'))
    end

    it 'runs the command' do
      script.expects(:run_stage).with(:before_deploy)
      script.expects(:if).with(' ! $TRAVIS_PULL_REQUEST = false').yields(script)
      script.expects(:if).with(' ! $TRAVIS_BRANCH = staging || $TRAVIS_BRANCH = production').yields(script)
      script.expects(:if).with('($TRAVIS_PULL_REQUEST = false) && ($TRAVIS_BRANCH = staging || $TRAVIS_BRANCH = production)').yields(script)
      script.expects(:cmd).with('rvm 1.9.3 --fuzzy do ruby -S gem install dpl', assert: true, echo: false)
      script.expects(:cmd).with(<<-DPL.gsub(/\s+/, ' ').strip, assert: false, echo: false)
        rvm 1.9.3 --fuzzy do ruby -S dpl --provider="heroku" --app="foo" --fold;
        if [ $? -ne 0 ]; then echo "failed to deploy"; travis_terminate 2; fi
      DPL
      script.expects(:cmd).with("echo -e \"\e[33;1mSkipping deployment with the heroku provider because the current build is a pull request.\e[0m\"", {:echo => false, :assert => false, :fold => 'deployment'})
      script.expects(:cmd).with("echo -e \"\e[33;1mSkipping deployment with the heroku provider because this branch is not permitted to deploy.\e[0m\"", {:echo => false, :assert => false, :fold => 'deployment'})
      script.expects(:run_stage).with(:after_deploy)
      subject.deploy
    end
  end

  describe 'on tags' do
    let(:config) {{ provider: "heroku", on: { tags: true } }}

    it 'runs the command' do
      script.expects(:run_stage).with(:before_deploy)
      script.expects(:if).with(' ! $TRAVIS_PULL_REQUEST = false').yields(script)
      script.expects(:if).with(' ! $TRAVIS_BRANCH = master').yields(script)
      script.expects(:if).with(" ! \"$TRAVIS_TAG\" != \"\"").yields(script)
      script.expects(:if).with('($TRAVIS_PULL_REQUEST = false) && ($TRAVIS_BRANCH = master) && ("$TRAVIS_TAG" != "")').yields(script)
      script.expects(:cmd).with('rvm 1.9.3 --fuzzy do ruby -S gem install dpl', assert: true, echo: false)
      script.expects(:cmd).with(<<-DPL.gsub(/\s+/, ' ').strip, assert: false, echo: false)
        rvm 1.9.3 --fuzzy do ruby -S dpl --provider="heroku" --fold;
        if [ $? -ne 0 ]; then echo "failed to deploy"; travis_terminate 2; fi
      DPL
      script.expects(:cmd).with("echo -e \"\e[33;1mSkipping deployment with the heroku provider because the current build is a pull request.\e[0m\"", {:echo => false, :assert => false, :fold => 'deployment'})
      script.expects(:cmd).with("echo -e \"\e[33;1mSkipping deployment with the heroku provider because this branch is not permitted to deploy.\e[0m\"", {:echo => false, :assert => false, :fold => 'deployment'})
      script.expects(:cmd).with("echo -e \"\e[33;1mSkipping deployment with the heroku provider because this is not a tagged commit.\e[0m\"", {:echo => false, :assert => false, :fold => 'deployment'})
      script.expects(:run_stage).with(:after_deploy)
      subject.deploy
    end
  end

  describe 'multiple providers' do
    let(:config) { [{provider: "heroku", password: "foo", email: "foo@blah.com", on: { condition: "$ENV_1 = 1"}},
                    {provider: "nodejitsu", user: "foo", api_key: "bar", on: { condition: "$ENV_2 = 2"}}] }

    it 'runs the command' do
      script.expects(:run_stage).with(:before_deploy).twice
      script.expects(:if).with(' ! $TRAVIS_PULL_REQUEST = false').yields(script).twice
      script.expects(:if).with(' ! $TRAVIS_BRANCH = master').yields(script).twice
      script.expects(:if).with(' ! $ENV_1 = 1').yields(script)
      script.expects(:if).with(' ! $ENV_2 = 2').yields(script)
      script.expects(:if).with('($TRAVIS_PULL_REQUEST = false) && ($TRAVIS_BRANCH = master) && ($ENV_1 = 1)').yields(script).once
      script.expects(:if).with('($TRAVIS_PULL_REQUEST = false) && ($TRAVIS_BRANCH = master) && ($ENV_2 = 2)').yields(script).once
      script.expects(:cmd).with('rvm 1.9.3 --fuzzy do ruby -S gem install dpl', assert: true, echo: false).twice
      script.expects(:cmd).with(<<-DPL.gsub(/\s+/, ' ').strip, assert: false, echo: false)
        rvm 1.9.3 --fuzzy do ruby -S dpl --provider="heroku" --password="foo" --email="foo@blah.com" --fold;
        if [ $? -ne 0 ]; then echo "failed to deploy"; travis_terminate 2; fi
      DPL
      script.expects(:run_stage).with(:after_deploy).twice

      script.expects(:cmd).with(<<-DPL.gsub(/\s+/, ' ').strip, assert: false, echo: false)
        rvm 1.9.3 --fuzzy do ruby -S dpl --provider="nodejitsu" --user="foo" --api_key="bar" --fold;
        if [ $? -ne 0 ]; then echo "failed to deploy"; travis_terminate 2; fi
      DPL
      script.expects(:cmd).with("echo -e \"\e[33;1mSkipping deployment with the heroku provider because the current build is a pull request.\e[0m\"", {:echo => false, :assert => false, :fold => 'deployment'})
      script.expects(:cmd).with("echo -e \"\e[33;1mSkipping deployment with the nodejitsu provider because the current build is a pull request.\e[0m\"", {:echo => false, :assert => false, :fold => 'deployment'})
      script.expects(:cmd).with("echo -e \"\e[33;1mSkipping deployment with the heroku provider because this branch is not permitted to deploy.\e[0m\"", {:echo => false, :assert => false, :fold => 'deployment'})
      script.expects(:cmd).with("echo -e \"\e[33;1mSkipping deployment with the nodejitsu provider because this branch is not permitted to deploy.\e[0m\"", {:echo => false, :assert => false, :fold => 'deployment'})
      script.expects(:cmd).with("echo -e \"\e[33;1mSkipping deployment with the heroku provider because a custom condition was not met.\e[0m\"", {:echo => false, :assert => false, :fold => 'deployment'})
      script.expects(:cmd).with("echo -e \"\e[33;1mSkipping deployment with the nodejitsu provider because a custom condition was not met.\e[0m\"", {:echo => false, :assert => false, :fold => 'deployment'})
      subject.deploy
    end
  end

  describe 'allow_failure' do
    let(:config) {{ provider: "heroku", password: 'foo', email: 'user@host', allow_failure: true }}

    it 'runs the command' do
      script.expects(:run_stage).with(:before_deploy)
      script.expects(:if).with(' ! $TRAVIS_PULL_REQUEST = false').yields(script)
      script.expects(:if).with(' ! $TRAVIS_BRANCH = master').yields(script)
      script.expects(:if).with('($TRAVIS_PULL_REQUEST = false) && ($TRAVIS_BRANCH = master)').yields(script)
      script.expects(:cmd).with('rvm 1.9.3 --fuzzy do ruby -S gem install dpl', assert: false, echo: false)
      script.expects(:cmd).with(<<-DPL.gsub(/\s+/, ' ').strip, assert: false, echo: false)
        rvm 1.9.3 --fuzzy do ruby -S dpl --provider="heroku" --password="foo" --email="user@host" --fold
      DPL
      script.expects(:cmd).with("echo -e \"\e[33;1mSkipping deployment with the heroku provider because the current build is a pull request.\e[0m\"", {:echo => false, :assert => false, :fold => 'deployment'})
      script.expects(:cmd).with("echo -e \"\e[33;1mSkipping deployment with the heroku provider because this branch is not permitted to deploy.\e[0m\"", {:echo => false, :assert => false, :fold => 'deployment'})
      script.expects(:run_stage).with(:after_deploy)
      subject.deploy
    end
  end
end
