require 'spec_helper'

describe Build::Remote do
  let(:job)    { stub('job:configure', :run => { :foo => 'foo' }) }
  let(:shell)  { stub('shell', :connect => nil, :on_output => nil, :close => nil) }
  let(:runner) { Build::Remote.new(nil, shell, job) }

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
