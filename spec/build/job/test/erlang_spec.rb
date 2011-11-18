require 'spec_helper'

describe Build::Job::Test::Erlang do
  let(:shell)  { stub('shell') }
  let(:config) { Build::Job::Test::Erlang::Config.new }
  let(:job)    { Build::Job::Test::Erlang.new(shell, nil , config) }

  describe 'config' do
    it 'defaults :opt_release to "R14B02"' do
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
    it 'returns "./rebar get-deps" if a rebar.config file exists' do
      job.expects(:rebar_configured?).returns(true)
      job.install.should == './rebar get-deps'
    end

    it 'returns nil if no rebar.config file exists' do
      job.expects(:rebar_configured?).returns(false)
      job.install.should be_nil
    end
  end

  describe 'script' do
    it 'returns "./rebar compile && ./rebar skip_deps=true eunit" if a rebar.config file exists' do
      job.expects(:rebar_configured?).returns(true)
      job.send(:script).should == './rebar compile && ./rebar skip_deps=true eunit'
    end

    it 'returns "make test" if a rebar.config file does not exist' do
      job.expects(:rebar_configured?).returns(false)
      job.send(:script).should == 'make test'
    end
  end
end


