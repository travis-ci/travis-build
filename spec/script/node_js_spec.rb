require 'spec_helper'

describe Travis::Build::Script::NodeJs do
  let(:options) { { logs: { build: false, state: false } } }
  let(:data)    { PAYLOADS[:push].deep_clone }

  subject { described_class.new(data, options).compile }

  it 'sets TRAVIS_NODE_VERSION' do
    is_expected.to set 'TRAVIS_NODE_VERSION', '0.10'
    store_example
  end

  it 'sets up the node version' do
    is_expected.to travis_cmd 'nvm use 0.10', echo: true, timing: true, assert: true
  end

  it 'disables the npm spinner' do
    is_expected.to travis_cmd 'npm config set spin false', echo: false, timing: true, assert: true
  end

  it 'announces node --version' do
    is_expected.to announce 'node --version'
  end

  it 'announces npm --version' do
    is_expected.to announce 'npm --version'
  end

  describe 'if no package.json exists' do
    it 'runs make test' do
      is_expected.to travis_cmd 'make test', echo: true, timing: true
    end
  end

  describe 'if package.json exists' do
    before(:each) do
      file('package.json')
      data['config']['npm_args'] = '--npm-args'
    end

    it 'installs with npm install --npm-args' do
      is_expected.to travis_cmd 'npm install --npm-args', echo: true, timing: true, assert: true, retry: true
      store_example 'npm_args'
    end

    it 'runs npm test' do
      is_expected.to travis_cmd 'npm test', echo: true, timing: true
    end
  end

  describe 'if an npm cache is set' do
    before(:each) do
      file('package.json')
    end

    it 'installs an npm proxy and registry' do
      data['hosts'] = {'npm_cache' => 'http://npm.cache.com'}
      data['config']['cache'] = 'npm'
      is_expected.to run 'npm config set registry http://registry.npmjs.org', echo: false, assert: false
      is_expected.to run 'npm config set proxy http://npm.cache.com', echo: false, assert: false
    end

    it "doesn't install a proxy when caching is disabled" do
      data['hosts'] = {'npm_cache' => 'http://npm.cache.com'}
      is_expected.not_to run 'npm config set registry http://registry.npmjs.org', echo: false, assert: false
      is_expected.not_to run 'npm config set proxy http://npm.cache.com', echo: false, assert: false
    end

    it "doesn't install a proxy when no host is configured" do
      data['config']['cache'] = 'npm'
      is_expected.not_to run 'npm config set registry http://registry.npmjs.org', echo: false, assert: false
      is_expected.not_to run 'npm config set proxy http://npm.cache.com', echo: false, assert: false
    end
  end

  describe 'node 0.6.x' do
    it 'sets strict-ssl to false for node 0.6.x' do
      ['0.6', '0.6.1', '0.6.99'].each do |version|
        data['config']['node_js'] = version
        is_expected.to run 'npm conf set strict-ssl false'
      end
    end

    it 'does not set strict-ssl to false for not node 0.6.x' do
      ['0.5.99', '0.7', '0.10'].each do |version|
        data['config']['node_js'] = version
        is_expected.not_to run 'npm conf set strict-ssl false'
      end
    end
  end
end
