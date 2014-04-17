require 'spec_helper'

describe Travis::Build::Data::Env do
  let(:data) { stub('data',
    secure_env_enabled?: false,
    pull_request: '100',
    config: { env: 'FOO=foo' },
    build: { id: '1', number: '1' },
    job: { id: '1', number: '1.1', branch: 'foo-(dev)', commit: '313f61b', commit_range: '313f61b..313f61a', commit_message: 'the commit message', os: 'linux' },
    repository: { slug: 'travis-ci/travis-ci' }
    ) }
  let(:env)  { described_class.new(data) }

  it 'vars respond to :key' do
    expect(env.vars.first).to respond_to(:key)
  end

  it 'includes all travis env vars' do
    travis_vars = env.vars.select { |v| v.key =~ /^TRAVIS_/ && v.value && v.value.length > 0 }
    expect(travis_vars.length).to eq(12)
  end

  it 'includes config env vars' do
    expect(env.vars.last.key).to eq('FOO')
  end

  it 'does not export secure env vars for pull requests' do
    data.stubs(:config).returns(env: 'SECURE FOO=foo')
    expect(env.vars.last.key).not_to eq('FOO')
  end

  it 'escapes TRAVIS_ vars as needed' do
    expect(env.vars.find { |var| var.key == 'TRAVIS_BRANCH' }.value).to eq("foo-\\(dev\\)")
  end

  context "with TRAVIS_BUILD_DIR including $HOME" do
    before do
      replace_const 'Travis::Build::BUILD_DIR', '$HOME'
    end

    after do
      replace_const 'Travis::Build::BUILD_DIR', './tmp'
    end

    it "shouldn't escape $HOME" do
      expect(env.vars.find {|var| var.key == 'TRAVIS_BUILD_DIR'}.value).to eq("$HOME/travis-ci/travis-ci")
    end

    it "should escape the repository slug" do
      data.stubs(:repository).returns(slug: 'travis-ci/travis-ci ci')
      expect(env.vars.find {|var| var.key == 'TRAVIS_BUILD_DIR'}.value).to eq("$HOME/travis-ci/travis-ci\\ ci")
    end
  end


end

