require 'spec_helper'
require 'travis/build'

describe Travis::Build::Job::Test::Ruby do
  let(:shell)  { stub('shell', :export_line => true, :execute => true, :evaluate => 'default', :cwd => '~/builds', :file_exists? => true) }
  let(:config) { Travis::Build::Job::Test::Ruby::Config.new(:bundler_args => '--binstubs') }
  let(:job)    { Travis::Build::Job::Test::Ruby.new(shell, nil, config) }

  describe 'config defaults' do
    it ':rvm to "default"' do
      config.rvm.should == 'default'
    end

    it ':gemfile to "Gemfile"' do
      config.gemfile.should == 'Gemfile'
    end
  end

  describe 'setup' do
    it 'switches to the given ruby version' do
      config.rvm = 'rbx'
      shell.expects(:execute).with('rvm use rbx', :echo => true).returns(true)
      job.setup
    end

    it 'announces activated ruby version' do
      shell.expects(:execute).with('ruby --version')
      job.setup
    end

    it 'raises AssertionFailed when rvm outputs an ERROR string' do
      config.rvm = 'rbx'
      shell.expects(:execute).with('rvm use rbx', :echo => true).returns(false)
      lambda { job.setup }.should raise_error(Travis::AssertionFailed)
    end

    it 'configures bundler to use the given gemfile if it exists' do
      job.expects(:gemfile?).returns(true)
      shell.expects(:cwd).returns('~/builds')
      shell.expects(:export_line).with('BUNDLE_GEMFILE=~/builds/Gemfile')
      job.setup
    end

    it 'does not configure bundler if the given gemfile does not exist' do
      job.expects(:gemfile?).returns(false)
      shell.expects(:export_line).never
      job.setup
    end
  end

  describe 'install' do
    it 'returns "bundle install --binstubs" if the given gemfile exists' do
      job.expects(:gemfile?).returns(true)
      job.install.should == "bundle install --binstubs"
    end

    it 'returns nil if the given gemfile does not exist' do
      job.expects(:gemfile?).returns(false)
      job.install.should be_nil
    end
  end

  describe 'script' do
    it 'returns "bundle exec rake" if a gemfile exists' do
      job.expects(:gemfile?).returns(true)
      job.send(:script).should == 'bundle exec rake'
    end

    it 'returns "rake" if a gemfile does not exist' do
      job.expects(:gemfile?).returns(false)
      job.send(:script).should == 'rake'
    end
  end
end
