require 'spec_helper'
require 'travis/build'

describe Travis::Build::Job::Test::C do
  let(:shell)  { stub('shell', :execute => true) }
  let(:config) { Travis::Build::Job::Test::C::Config.new }
  let(:job)    { Travis::Build::Job::Test::C.new(shell, Hashr.new(:repository => {
                                                                    :slug => "owner/repo"
                                                                  }), config) }

  describe 'config' do
    it 'defaults :compiler to "gcc"' do
      config.compiler.should == 'gcc'
    end
  end

  describe 'setup' do
    context "when compiler is not explicitly overriden" do
      it "uses gcc" do
        shell.expects(:export_line).with("CC=gcc").returns(true)
        job.setup
      end
    end

    context "when compiler is set to clang" do
      let(:config) { Travis::Build::Job::Test::C::Config.new(:compiler => "clang") }

      it "uses clang" do
        shell.expects(:export_line).with("CC=clang").returns(true)
        job.setup
      end
    end
  end

  describe 'install' do
    it 'does nothing by default' do
      job.install.should be_nil
    end
  end

  describe 'script' do
    it 'assumes autoconf + make' do
      job.script.should == './configure && make && make test'
    end
  end
end


