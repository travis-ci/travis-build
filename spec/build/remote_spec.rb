require 'spec_helper'
require 'travis/build'

describe Travis::Build::Remote do
  let(:events) { Travis::Build::Event::Factory.new(:id => 1) }
  let(:job)    { stub('job:configure', :run => { :foo => 'foo' }) }
  let(:shell)  { stub('shell', :connect => nil, :on_output => nil, :close => nil) }
  let(:runner) { Travis::Build::Remote.new(nil, shell, events, job) }

  describe 'with_shell' do
    it 'connects the shell' do
      shell.expects(:connect)
      runner.send(:with_shell) {}
    end

    it 'wires the shell to log output' do
      shell.expects(:on_output)
      runner.send(:with_shell) {}
    end

    it 'yields and returns the result' do
      runner.send(:with_shell) { :result }.should == :result
    end

    it 'closes the shell' do
      shell.expects(:close)
      runner.send(:with_shell) {}
    end
  end
end
