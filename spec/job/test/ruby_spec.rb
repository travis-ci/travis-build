require 'spec_helper'

describe Job::Test::Ruby do
  let(:shell)  { stub('shell', :export => true, :execute => true, :evaluate => 'default', :cwd => '~/builds', :file_exists? => true) }
  let(:config) { Job::Test::Ruby::Config.new(:bundler_args => '--binstubs') }
  let(:job)    { Job::Test::Ruby.new(shell, nil, config) }

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
      shell.expects(:evaluate).with('rvm use rbx', :echo => true)
      job.setup
    end

    it 'raises AssertionFailed when rvm outputs an ERROR string' do
      config.rvm = 'rbx'
      shell.expects(:evaluate).with('rvm use rbx', :echo => true).returns('ERROR: Unknown ruby interpreter version')
      lambda { job.setup }.should raise_error(AssertionFailed)
    end

    it 'configures bundler to use the given gemfile if it exists' do
      job.expects(:gemfile?).returns(true)
      shell.expects(:cwd).returns('~/builds')
      shell.expects(:export).with('BUNDLE_GEMFILE', '~/builds/Gemfile')
      job.setup
    end

    it 'does not configure bundler if the given gemfile does not exist' do
      job.expects(:gemfile?).returns(false)
      shell.expects(:export).never
      job.setup
    end
  end

  describe 'install' do
    it 'installs the bundle if the given gemfile exists' do
      job.expects(:gemfile?).returns(true)
      shell.expects(:execute).with('bundle install --binstubs', :timeout => :install).returns(true)
      job.install
    end

    it 'does not try to install the bundle if the given gemfile does not exist' do
      job.expects(:gemfile?).returns(false)
      shell.expects(:execute).never
      job.install
    end
  end

  describe 'script' do
    it 'prefers the script from the config' do
      config.script = 'custom'
      job.send(:script).should == 'custom'
    end

    it 'defaults to "bundle exec rake" if a gemfile exists' do
      job.expects(:gemfile?).returns(true)
      job.send(:script).should == 'bundle exec rake'
    end

    it 'defaults to "rake" if a gemfile does not exist' do
      job.expects(:gemfile?).returns(false)
      job.send(:script).should == 'rake'
    end
  end
end
