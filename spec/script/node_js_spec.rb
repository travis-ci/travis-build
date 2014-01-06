require 'spec_helper'

describe Travis::Build::Script::NodeJs do
  let(:options) { { logs: { build: false, state: false } } }
  let(:data)    { PAYLOADS[:push].deep_clone }

  subject { described_class.new(data, options).compile }

  it 'sets TRAVIS_NODE_VERSION' do
    should set 'TRAVIS_NODE_VERSION', '0.10'
    store_example
  end

  it 'sets up the node version' do
    should setup 'nvm use 0.10'
  end

  it 'announces node --version' do
    should announce 'node --version'
  end

  it 'announces npm --version' do
    should announce 'npm --version'
  end

  describe 'if no package.json exists' do
    it 'runs make test' do
      should run_script 'make test'
    end
  end

  describe 'if package.json exists' do
    before(:each) do
      file('package.json')
      data['config']['npm_args'] = '--npm-args'
    end

    it 'installs with npm install --npm-args' do
      should install 'npm install --npm-args', retry: true
      store_example 'npm_args'
    end

    it 'runs npm test' do
      should run_script 'npm test'
    end
  end

  describe 'if an npm cache is set' do
    before(:each) do
      file('package.json')
    end

    it 'installs an npm proxy and registry' do
      data['hosts'] = {'npm_cache' => 'http://npm.cache.com'}
      data['config']['cache'] = 'npm'
      should run 'npm config set registry http://registry.npmjs.org', echo: false, assert: false
      should run 'npm config set proxy http://npm.cache.com', echo: false, assert: false
    end

    it "doesn't install a proxy when caching is disabled" do
      data['hosts'] = {'npm_cache' => 'http://npm.cache.com'}
      should_not run 'npm config set registry http://registry.npmjs.org', echo: false, assert: false
      should_not run 'npm config set proxy http://npm.cache.com', echo: false, assert: false
    end

    it "doesn't install a proxy when no host is configured" do
      data['config']['cache'] = 'npm'
      should_not run 'npm config set registry http://registry.npmjs.org', echo: false, assert: false
      should_not run 'npm config set proxy http://npm.cache.com', echo: false, assert: false
    end
  end

  describe 'node 0.6.x' do
    it 'sets strict-ssl to false for node 0.6.x' do
      ['0.6', '0.6.1', '0.6.99'].each do |version|
        data['config']['node_js'] = version
        should run 'npm conf set strict-ssl false'
      end
    end

    it 'does not set strict-ssl to false for not node 0.6.x' do
      ['0.5.99', '0.7', '0.10'].each do |version|
        data['config']['node_js'] = version
        should_not run 'npm conf set strict-ssl false'
      end
    end
  end
end
