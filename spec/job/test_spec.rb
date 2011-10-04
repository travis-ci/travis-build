require 'spec_helper'
require 'hashr'

describe Job::Test do
  let(:shell)      { Shell.new(stub(:execute)) }
  let(:repository) { stub(:checkout => true) }
  let(:config)     { Hashr.new(:env => 'FOO=foo', :script => 'rake') }
  let(:job)        { Job::Test.new(shell, repository, '123456', config) }

  describe 'run' do
    it 'changes to the build dir' do
      shell.expects(:chdir).with('~/builds')
      job.run
    end

    it 'checks the given commit out from the repository' do
      repository.expects(:checkout).with('123456').returns(true)
      job.run
    end

    it 'sets the project up' do
      shell.expects(:export).with('FOO', 'foo')
      job.run
    end

    it 'installs dependencies' do
      job.expects(:install)
      job.run
    end

    it 'runs the scripts from the configuration' do
      job.expects(:run_scripts)
      job.run
    end

    it 'returns 0 if the last script returned true' do
      shell.expects(:execute).with('rake', :timeout => :script).returns(true)
      job.run.should be_true
    end

    it 'returns 1 if the last script returned false' do
      shell.expects(:execute).with('rake', :timeout => :script).returns(false)
      job.run.should be_false
    end

    it 'returns 1 if checkout raised an exception' do
      repository.expects(:checkout).returns(false)
      job.run.should be_false
    end
  end

  describe 'run_script' do
    it 'returns true if the given script yields true' do
      shell.expects(:execute).returns(true)
      job.send(:run_script, 'rake').should be_true
    end

    it 'returns false if the given script yields false (given a single line)' do
      shell.expects(:execute).returns(false)
      job.send(:run_script, 'rake').should be_false
    end

    it 'returns false if the given script yields false (given multiple lines)' do
      shell.expects(:execute).with('rake', any_parameters).returns(false)
      job.send(:run_script, "rake\nfoo").should be_false
    end
  end
end
