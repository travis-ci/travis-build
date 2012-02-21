require 'spec_helper'
require 'travis/build'
require 'hashr'

describe Travis::Build::Job::Test do
  let(:shell)  { stub('shell', :chdir => true, :export_line => true, :execute => true, :cwd => '~/builds', :file_exists? => true, :echo => nil) }
  let(:commit) { stub(:checkout => true) }
  let(:config) { Hashr.new(:env => 'FOO=foo', :script => 'rake') }
  let(:job)    { Travis::Build::Job::Test.new(shell, commit, config) }

  describe 'by_lang' do
    Test = Travis::Build::Job::Test

    it 'returns Test::Ruby for nil' do
      Test.by_lang(nil).should == Test::Ruby
    end

    it 'returns Test::Ruby for an unknown language' do
      Test.by_lang('brainfuck').should == Test::Ruby
    end

    it 'returns Test::Ruby for "ruby"' do
      Test.by_lang('ruby').should == Test::Ruby
      Test.by_lang('Ruby').should == Test::Ruby
    end

    it 'returns Test::Clojure for "clojure"' do
      Test.by_lang('clojure').should == Test::Clojure
      Test.by_lang('Clojure').should == Test::Clojure
    end

    it 'returns Test::Erlang for "erlang"' do
      Test.by_lang('erlang').should == Test::Erlang
      Test.by_lang('Erlang').should == Test::Erlang
    end

    # JRuby won't let us use a class named Java. MK.
    it 'returns Test::PureJava for "java"' do
      Test.by_lang('java').should == Test::PureJava
      Test.by_lang('JAVA').should == Test::PureJava
    end

    it 'returns Test::NodeJs for "node_js"' do
      Test.by_lang('node_js').should == Test::NodeJs
    end

    it 'returns Test::Php for "php"' do
      Test.by_lang('php').should == Test::Php
      Test.by_lang('PHP').should == Test::Php
    end

    it 'returns Test::Scala for "scala"' do
      Test.by_lang('scala').should == Test::Scala
      Test.by_lang('Scala').should == Test::Scala
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

  describe 'run_stages' do
    it 'runs all the command stages in order if they return true' do
      [:before_install, :install, :before_script, :script, :after_script].each do |stage|
        job.expects(:run_commands).with(stage).returns(true).once
      end
      job.send(:run_stages)
    end

    it 'does not run all the command stages if one returns false' do
      job.expects(:run_commands).with(:before_install).returns(true).once
      job.expects(:run_commands).with(:install).returns(false).once
      job.expects(:run_commands).with(:before_script).never
      job.send(:run_stages)
    end
  end

  describe 'run_commands' do
    before :each do
      job.config.clear
    end

    [:before_script, :script, :after_script].each do |stage|
      it "does not run any #{stage}s if the config does not define them" do
        job.expects(:run_command).never
        job.send(:run_commands, stage)
      end

      it "runs a single #{stage} defined in the config" do
        job.config[stage] = './foo'
        job.expects(:run_command).with(stage, './foo').returns(true)
        job.send(:run_commands, stage)
      end

      it "runs an array of #{stage}s defined in the config" do
        job.config[stage] =['./foo', './bar']
        job.expects(:run_command).with(stage, './foo').returns(true)
        job.expects(:run_command).with(stage, './bar').returns(true)
        job.send(:run_commands, stage)
      end
    end

    [:before_install, :install, :before_script, :script, :after_script].each do |stage|
      it "runs #{stage} as defined in the config" do
        job.config[stage] = "./#{stage}"
        job.expects(:run_command).with(stage,"./#{stage}").returns(true)
        job.send(:run_commands, stage)
      end
    end

    it 'does not run the second before_script if the first one fails' do
      job.config.before_script = ['./before', './before_another']

      job.expects(:run_command).with(:before_script, './before').returns(false)
      job.expects(:run_command).with(:before_script, './before_another').never

      job.send(:run_commands, :before_script)
    end
  end

  describe 'run_command' do
    it 'returns true if the given script yields true' do
      shell.expects(:execute).returns(true)
      job.send(:run_command, :script, './foo').should be_true
    end

    it 'returns false if the given script yields false' do
      shell.expects(:execute).returns(false)
      job.send(:run_command, :script, './foo').should be_false
    end

    it 'returns false if a Timeout::Error is raised' do
      shell.expects(:timeout).with(:script).returns(300)
      shell.expects(:execute).with('./foo', any_parameters).raises(Timeout::Error)
      job.send(:run_command, :script, './foo').should be_false
    end

    context "when a before_script has failed" do
      it 'echos a message to the shell' do
        job.config.before_script = './before'

        shell.expects(:execute).with('./before', { :timeout => :before_script }).returns(false)
        shell.expects(:echo).with("\n\nbefore_script: './before' returned false.")

        job.send(:run_command, :before_script, './before')
      end
    end

    context "when a before_script has timed out" do
      it 'echos a message to the shell' do
        job.config.before_script = './before'

        shell.expects(:timeout).with(:before_script).returns(300)
        shell.expects(:execute).with('./before', { :timeout => :before_script }).raises(Timeout::Error)
        shell.expects(:echo).with("\n\nbefore_script: Execution of './before' took longer than 300 seconds and was terminated. Consider rewriting your stuff in AssemblyScript, we've heard it handles Web Scale\342\204\242\n\n")

        job.send(:run_command, :before_script, './before')
      end
    end
  end
end
