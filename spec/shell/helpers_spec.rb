require 'spec_helper'

class ShellHelperMock
  include Shell::Helpers
end

describe Shell::Helpers do
  let(:helper) { ShellHelperMock.new }

  describe 'echoize' do
    it 'echo the command before executing it (1)' do
      helper.echoize('rake').should == "echo \\$\\ rake\nrake"
    end

    it 'echo the command before executing it (2)' do
      helper.echoize(['rvm use 1.9.2', 'FOO=bar rake ci']).should == "echo \\$\\ rvm\\ use\\ 1.9.2\nrvm use 1.9.2\necho \\$\\ FOO\\=bar\\ rake\\ ci\nFOO=bar rake ci"
    end

    it 'removes a prefix from the echo command' do
      helper.echoize('timetrap -t 900 rake').should == "echo \\$\\ rake\ntimetrap -t 900 rake"
    end
  end

  describe 'timetrap' do
    it 'wraps a command without env vars into a command without a timeout' do
      helper.timetrap('rake').should == 'timetrap rake'
    end

    it 'wraps a command without env vars into a command with a timeout' do
      helper.timetrap('rake', :timeout => 900).should == 'timetrap -t 900 rake'
    end

    it 'wraps a command with env vars into a command without a timeout' do
      helper.timetrap('FOO=bar rake').should == 'FOO=bar timetrap rake'
    end

    it 'wraps a command with env vars into a command with a timeout' do
      helper.timetrap('FOO=bar rake', :timeout => 900).should == 'FOO=bar timetrap -t 900 rake'
    end

    # This breaks scripts that contain SQL statements with a ;, e.g. 'mysql -e "create database foo;"'.
    # Would need a more sophisticated parser :/
    #
    # it 'wraps multiple commands with env vars into a command with a timeout' do
    #   helper.timetrap('FOO=bar rake ci:prepare; rake', :timeout => 900) 'FOO=bar timetrap -t 900 rake ci:prepare; -t 900 rake'
    # end
  end

  describe 'parse_cmd' do
    it 'given a command that contains env vars it returns an array containing env vars and the command' do
      helper.parse_cmd('FOO=bar rake').should == ['FOO=bar', 'rake']
    end

    it 'given a command that contains not env vars it returns an array containing nil and the command' do
      helper.parse_cmd('rake').should == [nil, 'rake']
    end
  end
end
