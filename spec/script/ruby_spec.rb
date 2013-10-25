require 'spec_helper'

describe Travis::Build::Script::Ruby do
  let(:options) { { logs: { build: false, state: false } } }
  let(:data)    { PAYLOADS[:push].deep_clone }

  subject { described_class.new(data, options).compile }

  after :all do
    store_example
  end

  it_behaves_like 'a build script'

  it 'sets TRAVIS_RUBY_VERSION' do
    should set 'TRAVIS_RUBY_VERSION', 'default'
  end

  it 'sets the default ruby if no :rvm config given' do
    should setup 'rvm use default'
  end

  it 'sets the ruby from config :rvm' do
    data['config']['rvm'] = 'rbx'
    should setup 'rvm use rbx'
  end

  it 'handles float values correctly for rvm values' do
    data['config']['rvm'] = 2.0
    should setup 'rvm use 2.0'
  end

  it 'sets BUNDLE_GEMFILE if a gemfile exists' do
    gemfile 'Gemfile.ci'
    should set 'BUNDLE_GEMFILE', File.join(ENV['PWD'], 'tmp/Gemfile.ci')
  end

  it 'announces ruby --version' do
    should announce 'ruby --version'
  end

  it 'announces rvm --version' do
    should announce 'rvm --version'
  end

  it 'installs with bundle install with the given bundler_args if a gemfile exists' do
    gemfile 'Gemfile.ci'
    should install 'bundle install'
  end

  it 'folds bundle install if a gemfile exists' do
    gemfile 'Gemfile.ci'
    should fold 'bundle install', 'install'
  end

  it "retries bundle install if a Gemfile exists" do
    gemfile "Gemfile.ci"
    should retry_script 'bundle install'
  end

  it 'runs bundle install --deployment if there is a Gemfile.lock' do
    gemfile('Gemfile')
    file('Gemfile.lock')
    should run_script 'bundle install --deployment'
  end

  it 'runs bundle install --deployment if there is a custom Gemfile.ci.lock' do
    gemfile('Gemfile.ci')
    file('Gemfile.ci.lock')
    should run_script 'bundle install --deployment'
  end

  it 'runs bundle exec rake if a gemfile exists' do
    gemfile 'Gemfile.ci'
    should run_script 'bundle exec rake'
  end

  it 'runs rake if a gemfile does not exist' do
    should run_script 'rake'
  end

  describe 'using a jdk' do
    before :each do
      data['config']['jdk'] = 'openjdk7'
    end

    after :each do
      store_example 'ruby_with_jdk'
    end

    it_behaves_like 'a jdk build'
  end

  describe 'not using a jdk' do
    it 'does not announce java' do
      should_not announce 'java'
    end

    it 'does not announce javac' do
      should_not announce 'javac'
    end
  end

  describe :cache_slug do
    subject { described_class.new(data, options) }
    its(:cache_slug) { should be == 'cache--rvm-default--gemfile-Gemfile' }

    describe 'with custom gemfile' do
      before { gemfile 'foo' }
      its(:cache_slug) { should be == 'cache--rvm-default--gemfile-foo' }
    end

    describe 'with custom ruby version' do
      before { data['config']['rvm'] = 'jruby' }
      its(:cache_slug) { should be == 'cache--rvm-jruby--gemfile-Gemfile' }
    end

    describe 'with custom jdk version' do
      before do
        data['config']['rvm'] = 'jruby'
        data['config']['jdk'] = 'openjdk7'
      end
      its(:cache_slug) { should be == 'cache--jdk-openjdk7--rvm-jruby--gemfile-Gemfile' }
    end
  end
end
