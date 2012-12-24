require 'spec_helper'

describe Travis::Build::Script::Ruby do
  let(:config) { PAYLOADS[:push].deep_clone }

  subject { described_class.new(config).compile }

  it_behaves_like 'a build script'

  it 'sets TRAVIS_RUBY_VERSION' do
    should set 'TRAVIS_RUBY_VERSION', 'default'
  end

  it 'sets the default ruby if no :rvm config given' do
    should run 'rvm use default', echo: true, log: true, assert: true
  end

  it 'sets the ruby from config :rvm' do
    config['config']['rvm'] = 'rbx'
    should run 'rvm use rbx', echo: true, log: true, assert: true
  end

  xit 'sets BUNDLE_GEMFILE if the gemfile exists' do
    gemfile 'Gemfile.ci'
    should set 'BUNDLE_GEMFILE', 'Gemfile.ci'
  end

  it 'runs ruby --version' do
    should run 'ruby --version', echo: true, log: true
  end

  it 'runs bundle install with the given bundler_args if the gemfile exists' do
    gemfile 'Gemfile.ci'
    should run 'bundle install', echo: true, log: true
  end

  it 'runs bundle exec rake if the gemfile exists' do
    gemfile 'Gemfile.ci'
    should run 'bundle exec rake', echo: true, log: true, timeout: timeout_for(:script)
  end

  it 'runs rake if the gemfile does not exist' do
    should run 'rake', echo: true, log: true, timeout: timeout_for(:script)
  end

  describe 'using jruby' do
    before :each do
      config['config']['rvm'] = 'jruby'
      config['config']['jdk'] = 'openjdk7'
    end

    it_behaves_like 'a jdk build'
  end
end
