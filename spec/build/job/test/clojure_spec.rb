require 'spec_helper'
require 'travis/build'

describe Travis::Build::Job::Test::Clojure do
  let(:shell)  { stub('shell', :execute => true) }

  describe 'config' do
    context "when Leiningen 1.7 is used" do
      let(:config) { described_class::Config.new }
      let(:job)    { described_class.new(shell, nil , config) }

      it 'defaults :install to "lein deps"' do
        job.install.should == 'lein deps'
      end

      it 'defaults :script to "lein test"' do
        job.script.should == 'lein test'
      end
    end

    context "when Leiningen 2.0 is used" do
      let(:config) { described_class::Config.new(:lein => "lein2") }
      let(:job)    { described_class.new(shell, nil , config) }

      it 'defaults :install to "lein deps"' do
        job.install.should == 'lein2 deps'
      end

      it 'defaults :script to "lein test"' do
        job.script.should == 'lein2 test'
      end
    end
  end



  describe "setup" do
    let(:shell)  { stub('shell') }

    context "when Leiningen 1.7 is used" do
      let(:config) { described_class::Config.new }
      let(:job)    { described_class.new(shell, nil , config) }

      it "announces Leiningen version" do
        shell.expects(:execute).with('lein version')

        job.setup
      end
    end

    context "when Leiningen 2.0 is used" do
      let(:config) { described_class::Config.new(:lein => "lein2") }
      let(:job)    { described_class.new(shell, nil , config) }

      it "announces Leiningen version" do
        shell.expects(:execute).with('lein2 version')

        job.setup
      end
    end
  end
end
