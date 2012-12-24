require 'spec_helper'

describe Travis::Build::Script::NodeJs do
  let(:config) { PAYLOADS[:push].deep_clone }

  subject { described_class.new(config).compile }

  it_behaves_like 'a build script'

  it 'sets TRAVIS_NODE_VERSION' do
    should set 'TRAVIS_NODE_VERSION', '0.4'
  end

  it 'sets up the node version' do
    should run 'nvm use 0.4', echo: true, log: true, assert: true
  end

  it 'announces node --version' do
    should run 'node --version', echo: true, log: true
  end

  it 'announces npm --version' do
    should run 'npm --version', echo: true, log: true
  end

  describe 'if no package.json exists' do
    it 'runs make test' do
      should run 'make test', echo: true, log: true, timeout: timeout_for(:script)
    end
  end

  describe 'if package.json exists' do
    before(:each) do
      file('package.json')
    end

    it 'installs with npm install --npm-args' do
      config['config']['npm_args'] = '--npm-args'
      should run 'npm install --npm-args'
    end

    it 'runs npm test' do
      should run 'npm test', echo: true, log: true, timeout: timeout_for(:script)
    end
  end
end
