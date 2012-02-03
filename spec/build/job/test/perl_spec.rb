require 'spec_helper'
require 'travis/build'

describe Travis::Build::Job::Test::Perl do
  let(:shell)  { stub('shell', :execute => true) }
  let(:config) { Travis::Build::Job::Test::Perl::Config.new }
  let(:job)    { Travis::Build::Job::Test::Perl.new(shell, nil , config) }

  describe 'config' do
    it 'defaults :perlbrew to "5.14"' do
      config.perlbrew.should == '5.14'
    end
  end

  describe 'setup' do
    context "when Perl version is not explicitly specified and we have to use the default one" do
      it 'switches to the default Perl version' do
        shell.expects(:export_line).with("TRAVIS_PERL_VERSION=5.14").returns(true)
        shell.expects(:execute).with('perlbrew use 5.14').returns(true)
        shell.expects(:execute).with('perl --version')

        job.setup
      end
    end

    context "when Perl version IS explicitly specified" do
      let(:config) { Travis::Build::Job::Test::Perl::Config.new(:perlbrew => "5.12") }

      it 'switches to the given php version' do
        shell.expects(:export_line).with("TRAVIS_PERL_VERSION=5.12").returns(true)
        shell.expects(:execute).with('perlbrew use 5.12').returns(true)
        shell.expects(:execute).with('perl --version')

        job.setup
      end
    end
  end

  describe 'install' do
    it 'returns nil' do
      job.install.should be_nil
    end
  end

  describe 'script' do
    it 'returns "cpanm . -v --no-interactive"' do
      job.send(:script).should == 'cpanm . -v --no-interactive'
    end
  end
end



