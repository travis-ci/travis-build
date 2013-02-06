require 'spec_helper'

describe Travis::Build::Data::Env do
  let(:data) { stub('data', pull_request: '100', config: { env: 'FOO=foo' }, build: { id: '1', number: '1' }, job: { id: '1', number: '1.1', branch: 'master', commit: '313f61b', commit_range: '313f61b..313f61a' }, repository: { slug: 'travis-ci/travis-ci' }) }
  let(:env)  { described_class.new(data) }

  it 'vars respond to :key' do
    env.vars.first.should respond_to(:key)
  end

  it 'includes all travis env vars' do
    travis_vars = env.vars.select { |v| v.key =~ /^TRAVIS_/ && v.value && v.value.length > 0 }
    travis_vars.length.should == 11
  end

  it 'includes config env vars' do
    env.vars.last.key.should == 'FOO'
  end

  it 'does not export secure env vars for pull requests' do
    data.stubs(:config).returns(env: 'SECURE FOO=foo')
    env.vars.last.key.should_not == 'FOO'
  end
end

