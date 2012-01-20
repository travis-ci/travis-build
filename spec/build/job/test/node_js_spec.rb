require 'spec_helper'
require 'travis/build'

describe Travis::Build::Job::Test::NodeJs do
  let(:shell)  { stub('shell') }
  let(:config) { Travis::Build::Job::Test::NodeJs::Config.new(:npm_args => '--dev') }
  let(:job)    { Travis::Build::Job::Test::NodeJs.new(shell, nil , config) }

  describe 'config' do
    it 'defaults :node_js to "0.4"' do
      config.node_js.should == '0.4'
    end

    it 'aliases :nodejs to :node_js' do
      config.nodejs.should == config.node_js
    end
  end

  describe 'setup' do
    it 'switches to the given nodejs version' do
      shell.expects(:execute).with("nvm use 0.4").returns(true)
      job.setup
    end
  end

  describe 'install' do
    it 'returns "npm install --dev" if a package file exists' do
      job.expects(:uses_npm?).returns(true)
      job.install.should == 'npm install --dev'
    end

    it 'does not try to install the package if no package file exists' do
      job.expects(:uses_npm?).returns(false)
      job.install.should be_nil
    end
  end

  describe 'script' do
    it 'returns "npm test" if a package file exists' do
      job.expects(:uses_npm?).returns(true)
      job.send(:script).should == 'npm test'
    end

    it 'returns "make test" if a package file does not exist' do
      job.expects(:uses_npm?).returns(false)
      job.send(:script).should == 'make test'
    end
  end
end

