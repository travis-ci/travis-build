require 'spec_helper'

describe Job::Test::Clojure do
  let(:shell)  { Shell.new(stub(:execute => true, :evaluate => '')) }
  let(:config) { Job::Test::Clojure::Config.new }
  let(:job)    { Job::Test::Clojure.new(shell, nil, nil , config) }

  describe 'install' do
    it 'installs the lein dependencies' do
      shell.expects(:execute).with('lein deps', :timeout => :install).returns(true)
      job.install
    end
  end

  describe 'script' do
    it 'prefers the script from the config' do
      config.script = 'custom'
      job.send(:script).should == 'custom'
    end

    it 'defaults to "lein test"' do
      config.script = nil
      job.send(:script).should == 'lein test'
    end
  end
end


