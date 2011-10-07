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

  describe 'run_scripts' do
    before :each do
      job.config.clear
    end

    [:before_script, :script, :after_script].each do |type|
      it "does not run any #{type}s if the config does not define them" do
        job.expects(:run_script).never
        job.send(:run_scripts)
      end

      it "runs a single #{type} defined in the config" do
        job.config[type] = './foo'
        job.expects(:run_script).with('./foo', :timeout => type)
        job.send(:run_scripts)
      end

      it "runs an array of #{type}s defined in the config" do
        job.config[type] =['./foo', './bar']
        job.expects(:run_script).with(['./foo', './bar'], :timeout => type)
        job.send(:run_scripts)
      end
    end

    it 'runs before_scripts, scripts and after_script as defined in the config' do
      job.config.before_script = './before'
      job.config.script = './script'
      job.config.after_script = './after'

      job.expects(:run_script).with('./before', any_parameters).returns(true)
      job.expects(:run_script).with('./script', any_parameters).returns(true)
      job.expects(:run_script).with('./after', any_parameters)

      job.send(:run_scripts)
    end

    it 'does not run scripts if a before_script has failed' do
      job.config.before_script = './before'
      job.config.script = './script'

      job.expects(:run_script).with('./before', any_parameters).returns(false)
      job.expects(:run_script).with('./script').never

      job.send(:run_scripts)
    end

    it 'does not run after_scripts if a script has failed' do
      job.config.script = './script'
      job.config.after_script = './after'

      job.expects(:run_script).with('./script', any_parameters).returns(false)
      job.expects(:run_script).with('./after').never

      job.send(:run_scripts)
    end
  end

  describe 'run_script' do
    it 'returns true if the given script yields true' do
      shell.expects(:execute).returns(true)
      job.send(:run_script, './foo').should be_true
    end

    it 'returns false if the given script yields false' do
      shell.expects(:execute).returns(false)
      job.send(:run_script, './foo').should be_false
    end

    it 'returns false if the first given script yields false' do
      shell.expects(:execute).with('./foo', any_parameters).returns(false)
      job.send(:run_script, ['./foo', './bar']).should be_false
    end
  end
end
