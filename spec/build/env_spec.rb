require 'spec_helper'

describe Travis::Build::Env do
  let(:payload) do
    {
      pull_request: '100',
      config: { env: 'FOO=foo' },
      build: { id: '1', number: '1' },
      job: { id: '1', number: '1.1', branch: 'foo-(dev)', commit: '313f61b', commit_range: '313f61b..313f61a', commit_message: 'the commit message', os: 'linux' },
      repository: { slug: 'travis-ci/travis-ci' },
      env_vars: [
        { name: 'BAR', value: 'bar', public: true },
        { name: 'BAZ', value: 'baz', public: false },
      ]
    }
  end

  let(:data) { Travis::Build::Data.new(payload) }
  let(:env)  { described_class.new(data) }
  let(:vars) { env.groups.flat_map(&:vars) }

  it 'includes travis env vars' do
    travis_vars = vars.select { |v| v.key =~ /^TRAVIS_/ }
    expect(travis_vars.length).to eq(14)
  end

  it 'includes config env vars' do
    var = vars.find { |v| v.key == 'FOO' }
    expect(var.value).to eq('foo')
    expect(var).not_to be_secure
  end

  it 'includes api env vars' do
    var = vars.find { |v| v.key == 'BAR' }
    expect(var.value).to eq('bar')
    expect(var).not_to be_secure
  end

  it 'includes private api env vars for secure envs' do
    data.stubs(:secure_env?).returns(true)
    var = vars.find { |v| v.key == 'BAZ' }
    expect(var.value).to eq('baz')
    expect(var).to be_secure
  end

  it 'does not include private api env vars for non-secure envs' do
    var = vars.find { |v| v.key == 'BAZ' }
    expect(var).to be_nil
  end

  it 'does not include secure env vars for pull requests' do
    payload[:config] = { env: 'SECURE FOO=foo' }
    expect(vars.last.key).not_to eq('FOO')
  end

  it 'does not include env vars that do not have a valid key' do
  end

  it 'escapes TRAVIS_ vars as needed' do
    expect(vars.find { |var| var.key == 'TRAVIS_BRANCH' }.value).to eq("foo-\\(dev\\)")
  end

  context "with TRAVIS_BUILD_DIR including $HOME" do
    it "shouldn't escape $HOME" do
      expect(vars.find {|var| var.key == 'TRAVIS_BUILD_DIR'}.value).to eq("$HOME/build/travis-ci/travis-ci")
    end

    it "should escape the repository slug" do
      payload[:repository][:slug] = 'travis-ci/travis-ci ci'
      expect(vars.find {|var| var.key == 'TRAVIS_BUILD_DIR'}.value).to eq("$HOME/build/travis-ci/travis-ci\\ ci")
    end
  end
end
