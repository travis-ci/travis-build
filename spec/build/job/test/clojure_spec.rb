require 'spec_helper'
require 'travis/build'

describe Travis::Build::Job::Test::Clojure do
  let(:shell)  { stub('shell', :execute => true) }
  let(:config) { described_class::Config.new }
  let(:job)    { described_class.new(shell, nil , config) }

  describe 'config' do
    it 'defaults :install to "lein deps"' do
      config.install.should == 'lein deps'
    end

    it 'defaults :script to "lein test"' do
      config.script.should == 'lein test'
    end
  end



  describe "setup" do
    let(:shell)  { stub('shell') }

    it "announces Leiningen version" do
      shell.expects(:execute).with('lein version')

      job.setup
    end
  end
end
