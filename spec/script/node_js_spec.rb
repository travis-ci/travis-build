require 'spec_helper'

describe Travis::Build::Script::NodeJs do
  let(:options) { { logs: { build: false, state: false } } }
  let(:data)    { PAYLOADS[:push].deep_clone }

  subject { described_class.new(data, options).compile }

  it 'sets TRAVIS_NODE_VERSION' do
    should set 'TRAVIS_NODE_VERSION', '0.4'
    store_example
  end

  it 'sets up the node version' do
    should setup 'nvm use 0.4'
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
end
