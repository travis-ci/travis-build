require 'spec_helper'
require 'travis/build'

describe Travis::Build::Job::Test::Scala do
  let(:shell)  { stub('shell') }
  let(:config) { described_class::Config.new }
  let(:job)    { described_class.new(shell, nil, config) }

  describe 'config' do
    it 'defaults :scala to "undefined"' do
      config.scala.should == 'undefined'
    end
  end

  describe 'setup' do
    it 'exports the Scala version to use for the build and announces it, without any validation' do
      config.scala = '0.0.7' # version validity is not verified
      shell.expects(:export_line).with('TRAVIS_SCALA_VERSION=0.0.7')
      shell.expects(:echo).with("Expect to run tests with Scala version '0.0.7'")
      job.setup
    end
  end

  describe 'script' do
    context "when configured to use Scala 2.8.2 with SBT" do
      it 'returns "sbt ++2.8.2 test"' do
        config.scala = '2.8.2'
        job.expects(:uses_sbt?).returns(true)
        job.send(:script).should == 'sbt ++2.8.2 test'
      end
    end

    context "when configured to use SBT without precising any Scala version" do
      it 'returns "sbt test"' do
        config.scala = 'undefined'
        job.expects(:uses_sbt?).returns(true)
        job.send(:script).should == 'sbt test'
      end
    end    

    context "when sbt is not used by the project" do
      it 'falls back to Maven' do
        job.expects(:uses_sbt?).returns(false)
        job.send(:script).should == 'mvn test'
      end
    end
  end
end
