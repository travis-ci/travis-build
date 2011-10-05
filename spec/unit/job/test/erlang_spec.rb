require 'spec_helper'

describe Job::Test::Erlang do
  let(:shell)  { stub('shell') }
  let(:config) { Job::Test::Erlang::Config.new }
  let(:job)    { Job::Test::Erlang.new(shell, nil , config) }

  describe 'config defaults' do
    it ':opt_release to "R14B02"' do
      config.opt_release.should == 'R14B02'
    end
  end

  describe 'setup' do
    it 'activates the given otp version' do
      shell.expects(:execute).with("source /home/vagrant/otp/R14B02/activate").returns(true)
      job.setup
    end
  end

  describe 'install' do
    it 'installs the rebar dependencies if a rebar.config file exists' do
      job.expects(:rebar_configured?).returns(true)
      shell.expects(:execute).with('./rebar get-deps', :timeout => :install).returns(true)
      job.install
    end

    it 'does not try to install the rebar dependencies if no rebar.config file exists' do
      job.expects(:rebar_configured?).returns(false)
      shell.expects(:execute).never
      job.install
    end
  end

  describe 'script' do
    it 'prefers the script from the config' do
      config.script = 'custom'
      job.send(:script).should == 'custom'
    end

    it 'defaults to "./rebar compile && ./rebar skip_deps=true eunit" if a rebar.config file exists' do
      job.expects(:rebar_configured?).returns(true)
      job.send(:script).should == './rebar compile && ./rebar skip_deps=true eunit'
    end

    it 'defaults to "make test" if a rebar.config file does not exist' do
      job.expects(:rebar_configured?).returns(false)
      job.send(:script).should == 'make test'
    end
  end
end


