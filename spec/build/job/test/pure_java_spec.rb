require 'spec_helper'
require 'travis/build'

describe Travis::Build::Job::Test::PureJava do
  let(:shell)  { stub('shell') }
  let(:config) { Travis::Build::Job::Test::PureJava::Config.new }
  let(:job)    { Travis::Build::Job::Test::PureJava.new(shell, nil, config) }

  describe 'install' do
    context "when project uses Maven" do
      it 'returns "mvn install"' do
        job.expects(:uses_maven?).returns(true)
        job.install.should == 'mvn install'
      end
    end

    it 'does not do anything if project does not use Maven' do
      job.expects(:uses_maven?).returns(false)
      job.install.should be_nil
    end
  end


  describe 'script' do
    context "when configured to use Maven" do
      it 'returns "mvn test"' do
        job.expects(:uses_maven?).returns(true)
        job.send(:script).should == 'mvn test'
      end
    end

    context "when Maven is not used by the project" do
      it 'falls back to Ant' do
        job.expects(:uses_maven?).returns(false)
        job.send(:script).should == 'ant test'
      end
    end
  end
end
