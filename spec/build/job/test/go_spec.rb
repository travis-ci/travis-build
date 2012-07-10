require 'spec_helper'
require 'travis/build'

describe Travis::Build::Job::Test::Go do
  let(:shell)  { stub('shell') }
  let(:config) { Travis::Build::Job::Test::Go::Config.new }
  let(:job)    { Travis::Build::Job::Test::Go.new(shell, Hashr.new(:repository => {
                                                                     :slug => "owner/repo"
                                                                   }), config) }

  describe 'install' do
    context "when Makefile file exists" do
      it 'returns a no-op operation' do
        job.expects(:uses_make?).returns(true)
        job.install.should be_nil
      end
    end

    context "when Makefile DOES NOT exist" do
      it 'uses go get' do
        job.expects(:uses_make?).returns(false)
        job.install.should == "go get -d -v && go build -v"
      end
    end
  end

  describe 'script' do
    context "when make file exists" do
      it 'returns "make"' do
        job.expects(:uses_make?).at_least_once.returns(true)
        job.send(:script).should == 'make'
      end
    end

    context "when Makefile DOES NOT exist" do
      it 'returns "go test -v"' do
        job.expects(:uses_make?).returns(false)
        job.send(:script).should == 'go test -v'
      end
    end
  end
end
