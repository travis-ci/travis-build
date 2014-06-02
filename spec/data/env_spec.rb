require 'spec_helper'

describe Travis::Build::Data::Env do
  let(:data) { stub('data',
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
    ) }
  let(:env)  { described_class.new(data) }

  it 'vars respond to :key' do
    env.vars.first.should respond_to(:key)
  end

  it 'includes all travis env vars' do
    travis_vars = env.vars.select { |v| v.key =~ /^TRAVIS_/ && v.value && v.value.length > 0 }
    travis_vars.length.should == 11
  end

  it 'includes config env vars' do
    var = env.vars.find { |v| v.key == 'FOO' }
    var.value.should == 'foo'
    var.should_not be_secure
  end

  it 'includes api env vars' do
    var = env.vars.find { |v| v.key == 'BAR' }
    var.value.should == 'bar'
    var.should_not be_secure

    var = env.vars.find { |v| v.key == 'BAZ' }
    var.value.should == 'baz'
    var.should be_secure
  end

  it 'does not export secure env vars for pull requests' do
    data.stubs(:config).returns(env: 'SECURE FOO=foo')
    env.vars.last.key.should_not == 'FOO'
  end

  it 'escapes TRAVIS_ vars as needed' do
    env.vars.find { |var| var.key == 'TRAVIS_BRANCH' }.value.should == "foo-\\(dev\\)"
  end

  context "with TRAVIS_BUILD_DIR including $HOME" do
    before do
      replace_const 'Travis::Build::BUILD_DIR', '$HOME'
    end

    after do
      replace_const 'Travis::Build::BUILD_DIR', './tmp'
    end

    it "shouldn't escape $HOME" do
      env.vars.find {|var| var.key == 'TRAVIS_BUILD_DIR'}.value.should == "$HOME/travis-ci/travis-ci"
    end

    it "should escape the repository slug" do
      data.stubs(:repository).returns(slug: 'travis-ci/travis-ci ci')
      env.vars.find {|var| var.key == 'TRAVIS_BUILD_DIR'}.value.should == "$HOME/travis-ci/travis-ci\\ ci"
    end
  end


end

