require 'spec_helper'
require 'travis/build'

describe Travis::Build::Job::Test::Clojure do
  let(:shell)  { stub('shell', :execute => true, :export_line => true) }
  let(:config) { described_class::Config.new }
  let(:job)    { described_class.new(shell, nil , config) }

  describe 'config' do
    context "when Leiningen 1.7 is used" do

      it 'defaults :install to "lein deps"' do
        job.install.should == 'lein deps'
      end

      it 'defaults :script to "lein test"' do
        job.script.should == 'lein test'
      end

      it 'defaults :jdk to "openjdk7"' do
        config.jdk.should == 'openjdk7'
      end
    end

    context "when Leiningen 2.0 is used" do
      let(:config) { described_class::Config.new(:lein => "lein2") }

      it 'defaults :install to "lein deps"' do
        job.install.should == 'lein2 deps'
      end

      it 'defaults :script to "lein test"' do
        job.script.should == 'lein2 test'
      end
    end
  end



  describe "setup" do
    context "when JDK version is not explicitly specified and we have to use the default one" do
      it 'switches to the default JDK version' do
        shell.expects(:export_line).with("TRAVIS_JDK_VERSION=openjdk7").returns(true)
        shell.expects(:execute).with('sudo jdk-switcher use openjdk7').returns(true)
        shell.expects(:execute).with('java -version')
        shell.expects(:execute).with('javac -version')
        job.setup
      end
    end

    context "when JDK version IS explicitly specified" do
      let(:config) { described_class::Config.new(:jdk => "openjdk6") }

      it 'switches to the given JDK version' do
        shell.expects(:export_line).with("TRAVIS_JDK_VERSION=openjdk6").returns(true)
        shell.expects(:execute).with('sudo jdk-switcher use openjdk6').returns(true)
        shell.expects(:execute).with('java -version')
        shell.expects(:execute).with('javac -version')
        job.setup
      end
    end

    context "when Leiningen 1.7 is used" do
      it "announces Leiningen version" do
        shell.expects(:execute).with('lein version')

        job.setup
      end
    end

    context "when Leiningen 2.0 is used" do
      let(:config) { described_class::Config.new(:lein => "lein2") }

      it "announces Leiningen version" do
        shell.expects(:execute).with('lein2 version')

        job.setup
      end
    end
  end
end
