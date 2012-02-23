require 'spec_helper'
require 'travis/build'

describe Travis::Build::Job::Test::Python do
  let(:shell) { stub('shell') }
  let(:config) { Travis::Build::Job::Test::Python::Config.new(:python => "3.2") }
  let(:job) { Travis::Build::Job::Test::Python.new(shell, nil, config) }


  describe 'setup' do
    it 'switches Python version using Pythonbrew, then announces it' do
      shell.expects(:export_line).with("TRAVIS_PYTHON_VERSION=3.2").returns(true)
      shell.expects(:execute).with("source ~/virtualenv/python3.2/bin/activate").returns(true)
      shell.expects(:execute).with("python --version").returns(true)
      shell.expects(:execute).with("pip --version").returns(true)

      job.setup
    end
  end


  describe 'install' do
    context "when Requirements.txt is found in the repository root" do
      it "returns pip install -r Requirements.txt" do
        shell.expects(:file_exists?).with("Requirements.txt").at_least_once.returns(true)
        job.install.should == "pip install -r Requirements.txt"
      end
    end

    context "when requirements.txt is found in the repository root" do
      it "returns pip install -r requirements.txt" do
        shell.expects(:file_exists?).with("Requirements.txt").at_least_once.returns(false)
        shell.expects(:file_exists?).with("requirements.txt").at_least_once.returns(true)
        job.install.should == "pip install -r requirements.txt"
      end
    end

    context "when neither requirements.txt nor Requirements.txt is found in the repository root" do
      it "echoes that requirements file isn't found" do
        job.expects(:requirements_file_found?).returns(false)
        job.install.should == "echo 'Could not locate requirements.txt, not installing dependencies. Override install: key in your .travis.yml to install dependencies the way your project needs.'"
      end
    end
  end


  describe 'script' do
  end
end
