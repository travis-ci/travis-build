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

  it 'sets BUNDLE_GEMFILE if the gemfile exists' do
    gemfile 'Gemfile.ci'
    should set 'BUNDLE_GEMFILE', '$PWD/Gemfile.ci'
  end

  it 'announces ruby --version' do
    should announce 'ruby --version'
  end

  it 'installs with bundle install with the given bundler_args if the gemfile exists' do
    gemfile 'Gemfile.ci'
    should install 'bundle install'
  end

  it 'runs bundle exec rake if the gemfile exists' do
    gemfile 'Gemfile.ci'
    should run_script 'bundle exec rake'
  end

  it 'runs rake if the gemfile does not exist' do
    should run_script 'rake'
  end

  describe 'using jruby' do
    before :each do
      data['config']['rvm'] = 'jruby'
      data['config']['jdk'] = 'openjdk7'
    end

    after :each do
      store_example 'jruby'
    end

    it_behaves_like 'a jdk build'
  end

  describe 'not using jruby' do
    it 'does not announce java' do
      should_not announce 'java'
    end

    it 'does not announce javac' do
      should_not announce 'javac'
    end
  end
end
