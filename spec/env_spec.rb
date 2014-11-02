require 'spec_helper'

describe Travis::Build::Env do
  let(:data) {
    stub('data',
      secure_env_enabled?: false,
      pull_request: '100',
      config: { env: 'FOO=foo' },
      build: { id: '1', number: '1' },
      job: { id: '1', number: '1.1', branch: 'foo-(dev)', commit: '313f61b', commit_range: '313f61b..313f61a', commit_message: 'the commit message', os: 'linux' },
      repository: { slug: 'travis-ci/travis-ci' },
      raw_env_vars: [
        { name: 'BAR', value: 'bar', public: true },
        { name: 'BAZ', value: 'baz', public: false },
      ]
    )
  }
  let(:env)  { described_class.new(data) }

  it 'vars respond to :key' do
    expect(env.vars.first).to respond_to(:key)
  end

  it 'includes all travis env vars' do
    travis_vars = env.vars.select { |v| v.key =~ /^TRAVIS_/ && v.value && v.value.length > 0 }
    expect(travis_vars.length).to eq(11)
  end

  it 'includes config env vars' do
    var = env.vars.find { |v| v.key == 'FOO' }
    expect(var.value).to eq('foo')
    expect(var).not_to be_secure
  end

  it 'includes api env vars' do
    var = env.vars.find { |v| v.key == 'BAR' }
    expect(var.value).to eq('bar')
    expect(var).not_to be_secure

    var = env.vars.find { |v| v.key == 'BAZ' }
    expect(var.value).to eq('baz')
    expect(var).to be_secure
  end

  it 'does not export secure env vars for pull requests' do
    data.stubs(:config).returns(env: 'SECURE FOO=foo')
    expect(env.vars.last.key).not_to eq('FOO')
  end

  it 'escapes TRAVIS_ vars as needed' do
    expect(env.vars.find { |var| var.key == 'TRAVIS_BRANCH' }.value).to eq("foo-\\(dev\\)")
  end

  context "with TRAVIS_BUILD_DIR including $HOME" do
    it "shouldn't escape $HOME" do
      expect(env.vars.find {|var| var.key == 'TRAVIS_BUILD_DIR'}.value).to eq("$HOME/build/travis-ci/travis-ci")
    end

    it "should escape the repository slug" do
      data.stubs(:repository).returns(slug: 'travis-ci/travis-ci ci')
      expect(env.vars.find {|var| var.key == 'TRAVIS_BUILD_DIR'}.value).to eq("$HOME/build/travis-ci/travis-ci\\ ci")
    end
  end
end
