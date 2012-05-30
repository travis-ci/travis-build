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

  shared_examples 'ruby_setup' do
    it 'exports the given ruby version' do
      shell.expects(:export_line).with("TRAVIS_RUBY_VERSION=#{config.rvm}").returns(true)
      job.setup
    end

    it 'switches to the given ruby version' do
      shell.expects(:execute).with("rvm use #{config.rvm}", :echo => true).returns(true)
      job.setup
    end

    it 'announces activated ruby version' do
      shell.expects(:execute).with('ruby --version')
      shell.expects(:execute).with('gem --version')
      job.setup
    end

    it 'raises AssertionFailed when rvm outputs an ERROR string' do
      shell.expects(:execute).with("rvm use #{config.rvm}", :echo => true).returns(false)
      lambda { job.setup }.should raise_error(Travis::AssertionFailed)
    end

    it 'configures bundler to use the given gemfile if it exists' do
      job.expects(:uses_bundler?).returns(true)
      shell.expects(:cwd).returns('~/builds')
      shell.expects(:export_line).with('BUNDLE_GEMFILE=~/builds/Gemfile')
      job.setup
    end

    it 'does not configure bundler if the given gemfile does not exist' do
      job.expects(:uses_bundler?).returns(false)
      shell.expects(:export_line).never
      job.setup
    end
  end


  describe 'setup' do
    context "when JDK is not needed" do
      it 'does not setup JDK' do
        config.rvm = 'rbx'
        shell.expects(:execute).with('java -version').never
        shell.expects(:execute).with('javac -version').never
        job.setup
      end

      it_behaves_like 'ruby_setup' do
        let(:config) { described_class::Config.new(:rvm => 'rbx', :bundler_args => '--binstubs') }
      end
    end

    context "when JDK is needed: a JDK version is explicitly specified and language is JRuby" do
      it 'exports the given JDK version' do
        config.rvm = 'jruby'
        config.jdk = 'openjdk6'
        shell.expects(:export_line).with("TRAVIS_JDK_VERSION=openjdk6").returns(true)
        job.setup
      end

      it 'switches to the given JDK version' do
        config.rvm = 'jruby'
        config.jdk = 'openjdk6'
        shell.expects(:execute).with('jdk_switcher use openjdk6').returns(true)
        job.setup
      end

      it 'announces activated JDK version' do
        config.rvm = 'jruby'
        config.jdk = 'openjdk6'
        shell.expects(:execute).with('java -version')
        shell.expects(:execute).with('javac -version')
        job.setup
      end

      it_behaves_like 'ruby_setup' do
        let(:config) { described_class::Config.new(:rvm => 'rbx', :bundler_args => '--binstubs') }
      end
    end
  end

  describe 'install' do
    it 'returns "bundle install --binstubs" if the given gemfile exists' do
      job.expects(:uses_bundler?).returns(true)
      job.install.should == "bundle install --binstubs"
    end

    it 'returns nil if the given gemfile does not exist' do
      job.expects(:uses_bundler?).returns(false)
      job.install.should be_nil
    end
  end

  describe 'script' do
    it 'returns "bundle exec rake" if a gemfile exists' do
      job.expects(:uses_bundler?).returns(true)
      job.send(:script).should == 'bundle exec rake'
    end

    it 'returns "rake" if a gemfile does not exist' do
      job.expects(:uses_bundler?).returns(false)
      job.send(:script).should == 'rake'
    end
  end
end
