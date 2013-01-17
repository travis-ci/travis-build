require 'spec_helper'

describe Travis::Build::Data::Env do
  let(:data) { stub('data', pull_request: '100', config: { env: 'FOO=foo' }, build: {}, job: {}, repository: {}) }
  let(:env)  { described_class.new(data) }

  it 'vars respond to :key' do
    env.vars.first.should respond_to(:key)
  end

  it 'includes travis env vars' do
    env.vars.first.key.should =~ /^TRAVIS_/
  end

  it 'includes config env vars' do
    env.vars.last.key.should == 'FOO'
  end

  it 'does not export secure env vars for pull requests' do
    data.stubs(:config).returns(env: 'SECURE FOO=foo')
    env.vars.last.key.should_not == 'FOO'
  end
end

