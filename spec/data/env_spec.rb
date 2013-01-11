require 'spec_helper'

describe Travis::Build::Data::Env do
  let(:data) { stub('data', pull_request?: false, config: { env: 'FOO=foo' }, build: {}, job: {}) }
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
end

