require 'spec_helper'

describe Travis::Build::Script::NodeJs do
  let(:options) { { logs: { build: true, state: true } } }
  let(:data)    { PAYLOADS[:push].deep_clone }

  subject { described_class.new(data, options).compile }

  it_behaves_like 'a build script'

  it 'sets TRAVIS_NODE_VERSION' do
    should set 'TRAVIS_NODE_VERSION', '0.4'
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
    end

    it 'installs with npm install --npm-args' do
      data['config']['npm_args'] = '--npm-args'
      should install 'npm install --npm-args'
    end

    it 'runs npm test' do
      should run_script 'npm test'
    end
  end
end
