require 'spec_helper'
require 'travis/build'

describe Travis::Build::Job::Test::Scala do
  let(:shell)  { stub('shell') }
  let(:config) { described_class::Config.new }
  let(:job)    { described_class.new(shell, nil, config) }

  describe 'config' do
    it 'defaults :scala to "2.9.1"' do
      config.scala.should == '2.9.1'
    end
  end

  describe 'setup' do
    it 'exports the Scala version to use for the build and announces it, without any validation' do
      config.scala = '0.0.7' # version validity is not verified
      shell.expects(:export_line).with('SCALA_VERSION=0.0.7')
      shell.expects(:export_line).with('TRAVIS_SCALA_VERSION=0.0.7')
      shell.expects(:echo).with('Using Scala 0.0.7')
      job.setup
    end
  end

  describe 'script' do
    context "when configured to use SBT 2.8.2" do
      it 'returns "sbt ++2.8.2 test"' do
        config.scala = '2.8.2'
        job.expects(:uses_sbt?).returns(true)
        job.send(:script).should == 'sbt ++2.8.2 test'
      end
    end

    context "when SBT is not used by the project" do
      it 'falls back to Maven' do
        job.expects(:uses_sbt?).returns(false)
        job.send(:script).should == 'mvn test'
      end
    end
  end
end
