require 'spec_helper'
require 'travis/build'

describe Travis::Build::Job::Test::Perl do
  let(:shell) { stub('shell') }
  let(:config) { Travis::Build::Job::Test::Perl::Config.new(:perl => "5.14") }
  let(:job) { Travis::Build::Job::Test::Perl.new(shell, nil, config) }


  describe 'setup' do
    it 'switches Perl version using Perlbrew, then announces it' do
      shell.expects(:execute).with("perlbrew use 5.14").returns(true)
      shell.expects(:execute).with("perl --version").returns(true)
      shell.expects(:execute).with("cpanm --version").returns(true)

      job.setup
    end
  end


  describe 'install' do
    it 'uses cpanm' do
      job.install.should == "cpanm --installdeps --notest ."
    end
  end


  describe 'script' do
    context "when project uses Build.PL" do
      it 'returns "perl Build.PL && ./Build test"' do
        job.expects(:uses_module_build?).returns(true)
        job.script.should == 'perl Build.PL && ./Build test'
      end
    end
    context "when project uses Makefile.PL" do
      it 'returns "perl Makefile.PL && make test"' do
        job.expects(:uses_module_build?).returns(false)
        job.expects(:uses_eumm?).returns(true)
        job.script.should == 'perl Makefile.PL && make test'
      end
    end

    context "when project uses neither Build.PL nor Makefile.PL" do
      it 'returns "make test"' do
        job.expects(:uses_module_build?).returns(false)
        job.expects(:uses_eumm?).returns(false)
        job.script.should == 'make test'
      end
    end
  end
end
