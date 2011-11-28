require 'spec_helper'
require 'travis/build'
require 'hashr'

describe Travis::Build::Job::Test do
  let(:shell)  { stub('shell', :chdir => true, :export => true, :execute => true, :cwd => '~/builds', :file_exists? => true, :echo => nil) }
  let(:commit) { stub(:checkout => true) }
  let(:config) { Hashr.new(:env => 'FOO=foo', :script => 'rake') }
  let(:job)    { Travis::Build::Job::Test.new(shell, commit, config) }

  describe 'by_lang' do
    it 'returns Travis::Build::Job::Test::Ruby for nil' do
      Travis::Build::Job::Test.by_lang(nil).should == Travis::Build::Job::Test::Ruby
    end

    it 'returns Travis::Build::Job::Test::Ruby for an unknown language' do
      Travis::Build::Job::Test.by_lang('brainfuck').should == Travis::Build::Job::Test::Ruby
    end

    it 'returns Travis::Build::Job::Test::Ruby for "ruby"' do
      Travis::Build::Job::Test.by_lang('ruby').should == Travis::Build::Job::Test::Ruby
    end

    it 'returns Travis::Build::Job::Test::Clojure for "clojure"' do
      Travis::Build::Job::Test.by_lang('clojure').should == Travis::Build::Job::Test::Clojure
    end

    it 'returns Travis::Build::Job::Test::Erlang for "erlang"' do
      Travis::Build::Job::Test.by_lang('erlang').should == Travis::Build::Job::Test::Erlang
    end

    it 'returns Travis::Build::Job::Test::NodeJs for "node_js"' do
      Travis::Build::Job::Test.by_lang('node_js').should == Travis::Build::Job::Test::NodeJs
    end

    it 'returns Travis::Build::Job::Test::Php for "php"' do
      Travis::Build::Job::Test.by_lang('php').should == Travis::Build::Job::Test::Php
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
      shell.expects(:export_line).with('FOO=foo')
      job.run
    end

    it 'installs dependencies' do
      job.expects(:install)
      job.run
    end

    it 'runs the scripts from the configuration' do
      job.expects(:run_commands)
      job.run
    end

    it 'returns { :status => 0 } if the last script returned true' do
      shell.expects(:execute).with('rake', :timeout => :script).returns(true)
      job.run.should == { :status => 0 }
    end

    it 'returns { :status => 1 } if the last script returned false' do
      shell.expects(:execute).with('rake', :timeout => :script).returns(false)
      job.run.should == { :status => 1 }
    end

    it 'returns { :status => 1 } if checkout raised an exception' do
      commit.expects(:checkout).returns(false)
      job.run.should == { :status => 1 }
    end
  end

  describe 'export' do
    it 'accepts a single string with multiple values' do
      s          = 'SUITE=integration'
      config.env = s
      shell.expects(:export_line).with(s)
      job.send(:export)
    end

    it 'accepts a single string with multiple values' do
      s          = 'FOO=foo BAR=2 BAZ="test values/baz"'
      config.env = s
      shell.expects(:export_line).with(s)
      job.send(:export)
    end

    it 'accepts an array of strings' do
      s1         = 'FOO=foo'
      s2         = 'BAR=bar BAZ="test test/ci"'

      config.env = [s1, s2]
      shell.expects(:export_line).with(s1)
      shell.expects(:export_line).with(s2)
      job.send(:export)
    end
  end

  describe 'run_commands' do
    before :each do
      job.config.clear
    end

    [:before_script, :script, :after_script].each do |type|
      it "does not run any #{type}s if the config does not define them" do
        job.expects(:run_command).never
        job.send(:run_commands)
      end

      it "runs a single #{type} defined in the config" do
        job.config[type] = './foo'
        job.expects(:run_command).with('./foo', :timeout => type).returns(true)
        job.send(:run_commands)
      end

      it "runs an array of #{type}s defined in the config" do
        job.config[type] =['./foo', './bar']
        job.expects(:run_command).with(['./foo', './bar'], :timeout => type).returns(true)
        job.send(:run_commands)
      end
    end

    it 'runs before_install, install, before_script, script and after_script as defined in the config' do
      %w(before_install install before_script script after_script).each do |command|
        job.config[command] = "./#{command}"
        job.expects(:run_command).with("./#{command}", :timeout => command.to_sym).returns(true)
      end
      job.send(:run_commands)
    end

    it 'does not run scripts if a before_script has failed' do
      job.config.before_script = './before'
      job.config.script = './script'

      job.expects(:run_command).with('./before', any_parameters).returns(false)
      job.expects(:run_command).with('./script').never

      job.send(:run_commands)
    end

    it 'echos a message to the shell if a before_script has failed' do
      job.config.before_script = './before'
      job.config.script = './script'

      job.expects(:run_command).with('./before', any_parameters).returns(false)
      shell.expects(:echo).with('before_script: ./before returned false.')

      job.send(:run_commands)
    end

    it 'does not run after_scripts if a script has failed' do
      job.config.script = './script'
      job.config.after_script = './after'

      job.expects(:run_command).with('./script', any_parameters).returns(false)
      job.expects(:run_command).with('./after').never

      job.send(:run_commands)
    end
  end

  describe 'run_command' do
    it 'returns true if the given script yields true' do
      shell.expects(:execute).returns(true)
      job.send(:run_command, './foo').should be_true
    end

    it 'returns false if the given script yields false' do
      shell.expects(:execute).returns(false)
      job.send(:run_command, './foo').should be_false
    end

    it 'returns false if the first given script yields false' do
      shell.expects(:execute).with('./foo', any_parameters).returns(false)
      job.send(:run_command, ['./foo', './bar']).should be_false
    end
  end
end
