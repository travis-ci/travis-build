require 'spec_helper'

describe Travis::Build::Script::NodeJs, :sexp do
  let(:data)   { PAYLOADS[:push].deep_clone }
  let(:script) { described_class.new(data) }
  subject      { script.sexp }

  it 'sets TRAVIS_NODE_VERSION' do
    should include_sexp [:export, ['TRAVIS_NODE_VERSION', '0.10']]
  end

  it 'sets up the node version' do
    should include_sexp [:cmd, 'nvm install 0.10', echo: true, assert: true, timing: true]
  end

  it 'announces node --version' do
    should include_sexp [:cmd, 'node --version', echo: true]
  end

  it 'announces npm --version' do
    should include_sexp [:cmd, 'npm --version', echo: true]
  end

  describe 'if package.json exists' do
    let(:sexp) { sexp_find(subject, [:if, '-f package.json'], [:then]) }

    it 'installs with npm install --npm-args' do
      data['config']['npm_args'] = '--npm-args'
      expect(sexp).to include_sexp [:cmd, 'npm install --npm-args', assert: true, echo: true, retry: true, timing: true]
    end
  end

  describe 'script' do
    let(:sexp) { sexp_filter(subject, [:if, '-f package.json'])[1] }

    it 'runs npm test if package.json exists' do
      branch = sexp_find(sexp, [:then])
      expect(sexp).to include_sexp [:cmd, 'npm test', echo: true, timing: true]
    end

    it 'runs make test if no package.json exists' do
      branch = sexp_find(sexp, [:else])
      expect(sexp).to include_sexp [:cmd, 'make test', echo: true, timing: true]
    end
  end

  describe 'if an npm cache is set' do
    let(:npm_set_registry) { [:cmd, 'npm config set registry http://registry.npmjs.org/', assert: true, echo: true] }
    let(:npm_set_proxy)    { [:cmd, 'npm config set proxy http://npm.cache.com', assert: true, echo: true] }

    it 'installs an npm proxy and registry' do
      data['hosts'] = {'npm_cache' => 'http://npm.cache.com'}
      data['config']['cache'] = 'npm'
      should include_sexp npm_set_registry
      should include_sexp npm_set_proxy
    end

    it "doesn't install a proxy when caching is not enabled" do
      data['hosts'] = {'npm_cache' => 'http://npm.cache.com'}
      should_not include_sexp npm_set_registry
      should_not include_sexp npm_set_proxy
    end

    it "doesn't install a proxy when no host is configured" do
      data['config']['cache'] = 'npm'
      should_not include_sexp npm_set_registry
      should_not include_sexp npm_set_proxy
    end
  end

  describe 'node 0.6.x' do
    let(:npm_set_strict_ssl) { [:cmd, 'npm conf set strict-ssl false', assert: true, echo: true] }
    ['0.6', '0.6.1', '0.6.99'].each do |version|
      it "sets strict-ssl to false for node #{version}" do
        data['config']['node_js'] = version
        should include_sexp npm_set_strict_ssl
      end
    end

    ['0.5.99', '0.7', '0.10'].each do |version|
      it "does not set strict-ssl to false for not node #{version}" do
        data['config']['node_js'] = version
        should_not include_sexp npm_set_strict_ssl
      end
    end
  end
end
