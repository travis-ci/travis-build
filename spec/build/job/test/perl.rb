require 'spec_helper'
require 'travis/build'

describe Travis::Build::Job::Test::Perl do
  let(:shell) { stub('shell') }
  let(:config) { Travis::Build::Job::Test::Perl::Config.new }
  let(:job) { Travis::Build::Job::Test::Perl.new(shell, nil, config) }

  describe 'install' do
    context "when project uses Build.PL" do
      it 'returns "perl Build.PL && ./Build test"' do
        job.expects(:uses_module_build?).returns(true)
        job.expects(:uses_eumm?).returns(false)
        job.install.should == 'perl Build.PL && ./Build test'
      end
    end
    context "when project uses Makefile.PL" do
      it 'returns "perl Makefile.PL && make test"' do
        job.expects(:uses_module_build?).returns(false)
        job.expects(:uses_eumm?).returns(true)
        job.install.should == 'perl Makefile.PL && make test'
      end
    end
  end
    context "when project uses neither Build.PL nor Makefile.PL" do
      it 'does nothing' do
        job.expects(:uses_module_build?).returns(false)
        job.expects(:uses_eumm?).returns(false)
        job.install.should be_nil
      end
    end
  end

end
