require 'spec_helper'
require 'travis/build'

describe Travis::Build::Job::Test::Scala do
  let(:shell)  { stub('shell') }
  let(:config) { Travis::Build::Job::Test::Scala::Config.new }
  let(:job)    { Travis::Build::Job::Test::Scala.new(shell, nil, config) }

  describe 'config' do
    it 'defaults :scala to "2.9.1"' do
      config.scala.should == '2.9.1'
    end
  end

  describe 'setup' do
    it 'exports the Scala version to use for the build and announces it, without any validation' do
      config.scala = '0.0.7' # version validity is not verified
      shell.expects(:export_line).with('SCALA_VERSION=0.0.7')
      shell.expects(:echo).with('Expect to build with Scala 0.0.7')
      job.setup
    end
  end

  describe 'script' do
    it 'returns "sbt ++2.8.2 test if configured for sbt and scala version is set to 2.8.2"' do
      config.scala = '2.8.2'
      job.expects(:configured_for_sbt?).returns(true)
      job.send(:script).should == 'sbt ++2.8.2 test'
    end

    it 'returns nil if not configured for sbt' do
      job.expects(:configured_for_sbt?).returns(false)
      job.script.should be_nil
    end
  end

end
