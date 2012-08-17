require 'spec_helper'
require 'travis/build'

describe Travis::Build::Job::Test::Python do
  let(:shell) { stub('shell') }
  let(:config) { Travis::Build::Job::Test::Python::Config.new(:python => "3.2") }
  let(:job) { Travis::Build::Job::Test::Python.new(shell, Hashr.new(:repository => {
                                                        :slug => "owner/repo"
                                                      }), config) }


  describe 'setup' do
    it 'switches Python version using Pythonbrew, then announces it' do
      shell.expects(:export_line).with("TRAVIS_PYTHON_VERSION=3.2").returns(true)
      shell.expects(:execute).with("source ~/virtualenv/python3.2/bin/activate").returns(true)
      shell.expects(:execute).with("python --version").returns(true)
      shell.expects(:execute).with("pip --version").returns(true)

      job.setup
    end
  end


  describe 'setup with PyPy' do
    let(:config) { Travis::Build::Job::Test::Python::Config.new(:python => "pypy") }

    it 'is treated as a special case' do
      shell.expects(:export_line).with("TRAVIS_PYTHON_VERSION=pypy").returns(true)
      shell.expects(:execute).with("source ~/virtualenv/pypy/bin/activate").returns(true)
      shell.expects(:execute).with("python --version").returns(true)
      shell.expects(:execute).with("pip --version").returns(true)

      job.setup
    end
  end


  describe 'setup with PyPy and virtualenv.system_site_packages enabled' do
    let(:config) { Travis::Build::Job::Test::Python::Config.new(:python => "pypy", :virtualenv => {:system_site_packages => true}) }

    it 'is treated as a special case' do
      shell.expects(:export_line).with("TRAVIS_PYTHON_VERSION=pypy").returns(true)
      shell.expects(:execute).with("source ~/virtualenv/pypy_with_system_site_packages/bin/activate").returns(true)
      shell.expects(:execute).with("python --version").returns(true)
      shell.expects(:execute).with("pip --version").returns(true)

      job.setup
    end
  end


  describe 'setup with 2.7 and virtualenv.system_site_packages enabled' do
    let(:config) { Travis::Build::Job::Test::Python::Config.new(:python => "2.7", :virtualenv => {:system_site_packages => true}) }

    it 'is treated as a special case' do
      shell.expects(:export_line).with("TRAVIS_PYTHON_VERSION=2.7").returns(true)
      shell.expects(:execute).with("source ~/virtualenv/python2.7_with_system_site_packages/bin/activate").returns(true)
      shell.expects(:execute).with("python --version").returns(true)
      shell.expects(:execute).with("pip --version").returns(true)

      job.setup
    end
  end


  describe 'install' do
    context "when Requirements.txt is found in the repository root" do
      it "returns pip install -r Requirements.txt" do
        shell.expects(:file_exists?).with("Requirements.txt").at_least_once.returns(true)
        job.install.should == "pip install -r Requirements.txt --use-mirrors"
      end
    end

    context "when requirements.txt is found in the repository root" do
      it "returns pip install -r requirements.txt" do
        shell.expects(:file_exists?).with("Requirements.txt").at_least_once.returns(false)
        shell.expects(:file_exists?).with("requirements.txt").at_least_once.returns(true)
        job.install.should == "pip install -r requirements.txt --use-mirrors"
      end
    end

    context "when neither requirements.txt nor Requirements.txt is found in the repository root" do
      it "echoes that requirements file isn't found" do
        job.expects(:requirements_file_found?).returns(false)
        job.install.should == "echo 'Could not locate requirements.txt in the repository root, not installing dependencies. Override install: key in your .travis.yml to install dependencies the way your project needs.'"
      end
    end
  end


  describe 'script' do
  end
end
