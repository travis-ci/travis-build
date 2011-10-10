require 'spec_helper'

describe Build::Job::Test::Nodejs do
  let(:shell)  { stub('shell') }
  let(:config) { Build::Job::Test::Nodejs::Config.new(:npm_args => '--dev') }
  let(:job)    { Build::Job::Test::Nodejs.new(shell, nil , config) }

  describe 'config defaults' do
    it ':nodejs_version to "0.4.11"' do
      config.nodejs_version.should == '0.4.11'
    end
  end

  describe 'setup' do
    it 'switches to the given nodejs version' do
      shell.expects(:execute).with("nvm use v0.4.11").returns(true)
      job.setup
    end
  end

  describe 'install' do
    it 'installs the package if a package file exists' do
      job.expects(:npm?).returns(true)
      shell.expects(:execute).with('npm install --dev', :timeout => :install).returns(true)
      job.install
    end

    it 'does not try to install the package if no package file exists' do
      job.expects(:npm?).returns(false)
      shell.expects(:execute).never
      job.install
    end
  end

  describe 'script' do
    it 'prefers the script from the config' do
      config.script = 'custom'
      job.send(:script).should == 'custom'
    end

    it 'defaults to "npm test" if a package file exists' do
      job.expects(:npm?).returns(true)
      job.send(:script).should == 'npm test'
    end

    it 'defaults to "make test" if a package file does not exist' do
      job.expects(:npm?).returns(false)
      job.send(:script).should == 'make test'
    end
  end
end

