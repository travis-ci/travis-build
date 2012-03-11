require 'spec_helper'
require 'travis/build'

describe Travis::Build::Job::Test::Groovy do
  let(:shell)  { stub('shell') }
  let(:config) { described_class::Config.new }
  let(:job)    { described_class.new(shell, nil, config) }

  describe 'install' do
    context "when project uses Gradle" do
      it 'returns "gradle assemble"' do
        job.expects(:uses_gradle?).returns(true)
        job.install.should == 'gradle assemble'
      end
    end

    context "when project uses Maven" do
      it 'returns "mvn install"' do
        job.expects(:uses_gradle?).returns(false)
        job.expects(:uses_maven?).returns(true)
        job.install.should == 'mvn install --quiet -DskipTests=true'
      end
    end

    context "when neither Maven nor Gradle are used by the project" do
      it 'does not do anything' do
        job.expects(:uses_maven?).returns(false)
        job.expects(:uses_gradle?).returns(false)
        job.install.should be_nil
      end
    end
  end


  describe 'script' do
    context "when project uses Gradle (build.gradle is available)" do
      it 'returns "gradle test"' do
        job.expects(:uses_gradle?).returns(true)
        job.send(:script).should == 'gradle check'
      end
    end

    context "when project uses Maven (pom.xml is available)" do
      it 'returns "mvn test"' do
        job.expects(:uses_gradle?).returns(false)
        job.expects(:uses_maven?).returns(true)
        job.send(:script).should == 'mvn test'
      end
    end

    context "when neither Maven nor Gradle are used by the project" do
      it 'falls back to Ant' do
        job.expects(:uses_maven?).returns(false)
        job.expects(:uses_gradle?).returns(false)
        job.send(:script).should == 'ant test'
      end
    end
  end
end
