require 'spec_helper'
require 'support/mock_shell'
require 'travis/build'
require 'hashr'

describe Travis::Build::Job::Test do
  let(:shell)  { MockShell.new(echo) }
  let(:echo)   { StringIO.new }
  let(:commit) { Hashr.new(:repository => {
                             :slug => "owner/repo",
                           },
                           :checkout     => true,
                           :pull_request => false) }
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


    it 'returns Test::C for "c"' do
      Test.by_lang('c').should == Test::C
      Test.by_lang('C').should == Test::C
    end

    it 'returns Test::Cpp for "cpp", "c++", "C++"' do
      Test.by_lang('cpp').should == Test::Cpp
      Test.by_lang('c++').should == Test::Cpp
      Test.by_lang('C++').should == Test::Cpp
      Test.by_lang('cplusplus').should == Test::Cpp
    end

    it 'returns Test::Clojure for "clojure"' do
      Test.by_lang('clojure').should == Test::Clojure
      Test.by_lang('Clojure').should == Test::Clojure
    end

    it 'returns Test::Erlang for "erlang"' do
      Test.by_lang('erlang').should == Test::Erlang
      Test.by_lang('Erlang').should == Test::Erlang
    end

    it 'returns Test::Go for "go"' do
      Test.by_lang('go').should == Test::Go
      Test.by_lang('GO').should == Test::Go
    end

    it 'returns Test::Haskell for "haskell"' do
      Test.by_lang('haskell').should == Test::Haskell
      Test.by_lang('Haskell').should == Test::Haskell
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
      shell.stubs(:export_line)
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

    it 'returns { :result => 0 } if the last script returned true' do
      shell.expects(:execute).with('rake', :stage => :script).returns(true)
      job.run.should == { :result => 0 }
    end

    it 'returns { :result => 1 } if the last script returned false' do
      shell.expects(:execute).with('rake', :stage => :script).returns(false)
      job.run.should == { :result => 1 }
    end

    it 'returns { :result => 1 } if checkout raised an exception' do
      commit.expects(:checkout).returns(false)
      job.run.should == { :result => 1 }
    end

    describe 'with a command timeout exception being raised' do
      before(:each) do
        job.stubs(:chdir).raises(Travis::Build::CommandTimeout.new(:script, 'rake', 1000))
      end

      it 'logs the exception' do
        job.run.should == { :result => 1 }
        echo.string.should match(/Executing your script \(rake\) took longer than 16 minutes and was terminated/)
      end
    end

    describe 'with an output exceeded exception being raised' do
      before(:each) do
        job.stubs(:chdir).raises(Travis::Build::OutputLimitExceeded.new(1000))
      end

      it 'logs the exception' do
        job.run.should == { :result => 1 }
        echo.string.should match(/The log length has exceeded the limit of 1000 Bytes/)
      end
    end
  end

  describe 'export' do
    context 'when we\'re dealing pull request' do
      it 'exports TRAVIS_PULL_REQUEST=true ENV var' do
        commit.expects(:pull_request?).at_least_once.returns(true)
        shell.stubs(:export_line)
        shell.expects(:export_line).with("TRAVIS_PULL_REQUEST=true")
        job.send(:export)
      end

      it 'exports TRAVIS_PULL_REQUEST_NUMBER ENV var' do
        commit.expects(:pull_request?).at_least_once.returns(true)
        commit.expects(:pull_request_number).at_least_once.returns(180)
        shell.stubs(:export_line)
        shell.expects(:export_line).with("TRAVIS_PULL_REQUEST_NUMBER=180")
        job.send(:export)
      end
    end

    it 'exports TRAVIS_PULL_REQUEST=false ENV var' do
      shell.stubs(:export_line)
      shell.expects(:export_line).with("TRAVIS_PULL_REQUEST=false")
      job.send(:export)
    end

    it 'exports TRAVIS_SECURE_ENV_VARS=false ENV var' do
      shell.stubs(:export_line)
      shell.expects(:export_line).with("TRAVIS_SECURE_ENV_VARS=false")
      job.send(:export)
    end

    context 'with secure env vars' do
      let(:config) { Hashr.new(:env => 'SECURE FOO=foo') }

      it 'exports TRAVIS_SECURE_ENV_VARS=true ENV var' do
        shell.stubs(:export_line)
        shell.expects(:export_line).with("TRAVIS_SECURE_ENV_VARS=true")
        job.send(:export)
      end
    end

    context 'when commit is a pull_request commit' do
      it 'sets TRAVIS specific env vars accordingly' do
        commit.expects(:pull_request?).at_least_once.returns(true)
        shell.stubs(:export_line)
        shell.expects(:export_line).with("TRAVIS_PULL_REQUEST=true")
        shell.expects(:export_line).with("TRAVIS_SECURE_ENV_VARS=false")
        job.send(:export)
      end
    end

    it 'accepts a single string with multiple values' do
      s          = 'SUITE=integration'
      config.env = s
      shell.stubs(:export_line)
      shell.expects(:export_line).with(s)
      job.send(:export)
    end

    it 'accepts a single string with multiple values' do
      s          = 'FOO=foo BAR=2 BAZ="test values/baz"'
      config.env = s
      shell.stubs(:export_line)
      shell.expects(:export_line).with(s)
      job.send(:export)
    end

    it 'accepts an array of strings' do
      s1         = 'FOO=foo'
      s2         = 'BAR=bar BAZ="test test/ci"'

      config.env = [s1, s2]
      shell.stubs(:export_line)
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

    context "when a before_script has failed" do
      it 'echos a message to the shell' do
        job.config.before_script = './before'

        shell.expects(:execute).with('./before', { :stage => :before_script }).returns(false)
        shell.expects(:echo).with("\n\nbefore_script: './before' returned false.")

        job.send(:run_command, :before_script, './before')
      end
    end
  end
end
