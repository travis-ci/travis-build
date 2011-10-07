require 'spec_helper'
require 'hashr'

describe Job::Test do
  let(:shell)  { stub('shell', :chdir => true, :export => true, :execute => true, :cwd => '~/builds', :file_exists? => true) }
  let(:commit) { stub(:checkout => true) }
  let(:config) { Hashr.new(:env => 'FOO=foo', :script => 'rake') }
  let(:job)    { Job::Test.new(shell, commit, config) }

  describe 'by_lang' do
    it 'returns Job::Test::Ruby for nil' do
      Job::Test.by_lang(nil).should == Job::Test::Ruby
    end

    it 'returns Job::Test::Ruby for an unknown language' do
      Job::Test.by_lang('brainfuck').should == Job::Test::Ruby
    end

    it 'returns Job::Test::Ruby for "ruby"' do
      Job::Test.by_lang('ruby').should == Job::Test::Ruby
    end

    it 'returns Job::Test::Clojure for "clojure"' do
      Job::Test.by_lang('clojure').should == Job::Test::Clojure
    end

    it 'returns Job::Test::Erlang for "erlang"' do
      Job::Test.by_lang('erlang').should == Job::Test::Erlang
    end

    it 'returns Job::Test::Nodejs for "nodejs"' do
      Job::Test.by_lang('nodejs').should == Job::Test::Nodejs
    end

    it 'returns Job::Test::Nodejs for "NodeJs"' do
      Job::Test.by_lang('NodeJs').should == Job::Test::Nodejs
    end

    it 'returns Job::Test::Nodejs for "node.js"' do
      Job::Test.by_lang('node.js').should == Job::Test::Nodejs
    end
  end

  describe 'run' do
    it 'changes to the build dir' do
      shell.expects(:chdir).with('~/builds')
      job.run
    end

    it 'checks the given commit out' do
      commit.expects(:checkout).returns(true)
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
      commit.expects(:checkout).returns(false)
      job.run.should be_false
    end
  end

  describe 'export' do
    it 'accepts a single string' do
      config.env = 'FOO=foo'
      shell.expects(:export).with('FOO', 'foo')
      job.send(:export)
    end

    it 'accepts an array of strings' do
      config.env = ['FOO=foo', 'BAR=bar']
      shell.expects(:export).with('FOO', 'foo')
      shell.expects(:export).with('BAR', 'bar')
      job.send(:export)
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
