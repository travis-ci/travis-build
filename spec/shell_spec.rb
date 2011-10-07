require 'spec_helper'

describe Shell do
  let(:session) { stub('session', :execute => true) }
  let(:shell)   { Shell.new(session) }

  describe 'export' do
    it 'exports a shell variable (no options given)' do
      session.expects(:execute).with('export FOO=bar')
      shell.export('FOO', 'bar')
    end

    it 'exports a shell variable (no options given)' do
      session.expects(:execute).with('export FOO=bar', :echo => true)
      shell.export('FOO', 'bar', :echo => true)
    end
  end

  describe 'chdir' do
    it 'silently creates the target directory using mkdir -p' do
      session.expects(:execute).with('mkdir -p ~/builds', :echo => false)
      shell.chdir('~/builds')
    end

    it 'cds into that directory' do
      session.expects(:execute).with('cd ~/builds')
      shell.chdir('~/builds')
    end
  end

  describe 'cwd' do
    it 'evaluates the current directory using pwd' do
      session.expects(:evaluate).with('pwd').returns("/home/vagrant/builds\n")
      shell.cwd.should == "/home/vagrant/builds"
    end
  end

  describe 'file_exists?' do
    it 'looks for a file using test -f' do
      session.expects(:execute).with('test -f Gemfile', :echo => false)
      shell.file_exists?('Gemfile')
    end
  end
end
