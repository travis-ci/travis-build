require 'spec_helper'
require 'travis/build'

describe Travis::Build::Job::Test::JvmLanguage do
  let(:shell)  { stub('shell') }
  let(:config) { described_class::Config.new }
  let(:job)    { described_class.new(shell, nil, config) }


  describe 'config' do
    it 'defaults :jdk to "default"' do
      config.jdk.should == 'default'
    end
  end

  describe 'setup' do
    context "when JDK version is not explicitly specified and we have to use the default one" do
      it 'switches to the default JDK version' do
        shell.expects(:export_line).with("TRAVIS_JDK_VERSION=default").returns(true)
        shell.expects(:execute).with('jdk_switcher use default').returns(true)
        shell.expects(:execute).with('java -version')
        shell.expects(:execute).with('javac -version')

        job.setup
      end
    end

    context "when JDK version IS explicitly specified" do
      let(:config) { Travis::Build::Job::Test::PureJava::Config.new(:jdk => "openjdk6") }

      it 'switches to the given JDK version' do
        shell.expects(:export_line).with("TRAVIS_JDK_VERSION=openjdk6").returns(true)
        shell.expects(:execute).with('jdk_switcher use openjdk6').returns(true)
        shell.expects(:execute).with('java -version')
        shell.expects(:execute).with('javac -version')

        job.setup
      end
    end
  end

  describe 'install' do
    context "when project uses Maven" do
      it 'returns "mvn install"' do
        job.expects(:uses_gradle?).returns(false)
        job.expects(:uses_maven?).returns(true)
        job.install.should == 'mvn install --quiet -DskipTests=true'
      end
    end

    context "when project uses Gradle" do
      it 'returns "gradle assemble"' do
        job.expects(:uses_gradle?).returns(true)
        job.install.should == 'gradle assemble'
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
    context "when project uses Maven (pom.xml is available but build.gradle is not)" do
      it 'returns "mvn test"' do
        job.expects(:uses_gradle?).returns(false)
        job.expects(:uses_maven?).returns(true)
        job.send(:script).should == 'mvn test'
      end
    end

    context "when project uses Gradle (build.gradle is available)" do
      it 'returns "gradle test"' do
        job.expects(:uses_gradle?).returns(true)
        job.send(:script).should == 'gradle check'
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
