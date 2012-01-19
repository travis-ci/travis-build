require 'spec_helper'
require 'travis/build'

describe Travis::Build::Job::Test::Erlang do
  let(:shell)  { stub('shell') }
  let(:config) { Travis::Build::Job::Test::Erlang::Config.new }
  let(:job)    { Travis::Build::Job::Test::Erlang.new(shell, nil , config) }

  describe 'config' do
    it 'defaults :otp_release to "R14B02"' do
      config.otp_release.should == 'R14B02'
    end
  end

  describe 'setup' do
    it 'activates the given otp version' do
      shell.expects(:execute).with("source /home/vagrant/otp/R14B02/activate").returns(true)
      job.setup
    end
  end

  describe 'install' do
    context "when a rebar.config file exists" do
      it 'returns "./rebar get-deps"' do
        job.expects(:uses_rebar?).returns(true)
        job.expects(:has_local_rebar?).returns(false)
        job.install.should == 'rebar get-deps'
      end
    end

    context "when a rebar.config file DOES NOT exist" do
      it 'returns nil' do
        job.expects(:uses_rebar?).returns(false)
        job.install.should be_nil
      end
    end
  end

  describe 'script' do
    context "when a rebar.config file exists" do
      context "and project DOES have local rebar (./rebar)" do
        it 'returns "./rebar compile && ./rebar skip_deps=true eunit"' do
          job.expects(:uses_rebar?).returns(true)
          job.expects(:has_local_rebar?).returns(true)
          job.send(:script).should == './rebar compile && ./rebar skip_deps=true eunit'
        end
      end

      context "and project DOES NOT have local rebar (./rebar)" do
        it 'returns "rebar compile && rebar skip_deps=true eunit"' do
          job.expects(:uses_rebar?).returns(true)
          job.expects(:has_local_rebar?).returns(false)
          job.send(:script).should == 'rebar compile && rebar skip_deps=true eunit'
        end
      end
    end

    context "when a rebar.config file DOES NOT exist" do
      it 'returns "make test"' do
        job.expects(:uses_rebar?).returns(false)
        job.send(:script).should == 'make test'
      end
    end
  end
end


