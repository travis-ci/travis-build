shared_examples_for 'a build script' do
  it 'clones the git repo' do
    cmd = 'git clone --depth=100 --quiet git://github.com/travis-ci/travis-ci.git travis-ci/travis-ci'
    timeout = Travis::Build::Data::DEFAULTS[:timeouts][:git_clone]
    should run cmd, echo: true, log: true, assert: true, timeout: timeout
  end

  it 'changes to the git repo dir' do
    should run 'cd travis-ci/travis-ci', timeout: false
  end

  it 'does not fetch a ref if not given' do
    should_not run 'git fetch'
  end

  it 'fetches a ref if given' do
    data['job']['ref'] = 'refs/pull/118/merge'
    cmd = 'git fetch origin +refs/pull/118/merge:'
    timeout = Travis::Build::Data::DEFAULTS[:timeouts][:git_fetch_ref]
    should run cmd, echo: true, log: true, assert: true, timeout: timeout
  end

  it 'removes the ssh key' do
    should run %r(rm -f .*\.ssh/source_rsa)
  end

  it 'checks the given commit out' do
    should run 'git checkout -qf 313f61b', echo: true, log: true
  end

  describe 'if .gitmodules exists' do
    before :each do
      file '.gitmodules'
    end

    it 'inits submodules' do
      should run 'git submodule init'
    end

    it 'updates submodules' do
      should run 'git submodule update'
    end
  end

  describe 'submodules is set to false' do
    before :each do
      file '.gitmodules'
      data['config']['git'] = { submodules: false }
    end

    it 'does not init submodules' do
      should_not run 'git submodule init'
    end

    it 'does not update submodules' do
      should_not run 'git submodule update'
    end
  end

  it 'sets TRAVIS_* env vars' do
    data['config']['env'].delete_if { |var| var =~ /SECURE / }

    should set 'TRAVIS_PULL_REQUEST',    'false'
    should set 'TRAVIS_SECURE_ENV_VARS', 'false'
    should set 'TRAVIS_BUILD_ID',        '1'
    should set 'TRAVIS_BUILD_NUMBER',    '1'
    should set 'TRAVIS_JOB_ID',          '1'
    should set 'TRAVIS_JOB_NUMBER',      '1.1'
    should set 'TRAVIS_BRANCH',          'master'
    should set 'TRAVIS_COMMIT',          '313f61b'
    should set 'TRAVIS_COMMIT_RANGE',    '313f61b..313f61a'
  end

  it 'sets TRAVIS_PULL_REQUEST to true when running a pull_request' do
    data['job']['pull_request'] = true
    should set 'TRAVIS_PULL_REQUEST', 'true'
  end

  it 'sets TRAVIS_SECURE_ENV_VARS to true when using secure env vars' do
    data['config']['env'] = 'SECURE BAR=bar'
    should set 'TRAVIS_SECURE_ENV_VARS', 'true'
  end

  it 'sets a given :env var' do
    data['config']['env'] = 'FOO=foo'
    should set 'FOO', 'foo'
  end

  it 'sets a given secure :env var' do
    data['config']['env'] = 'SECURE BAR=bar'
    should set 'BAR', 'bar'
  end

  it 'echoes obfuscated secure env vars' do
    data['config']['env'] = 'SECURE BAR=bar'
    should echo 'export BAR=[secure]'
  end

  it 'sets TRAVIS_TEST_RESULT' do
    should set 'TRAVIS_TEST_RESULT', '$?'
  end

  # TODO after_failure won't be called because the build script never returns 1
  %w(before_install install before_script script after_script after_success).each do |script|
    it "runs the given :#{script} script" do
      data['config'][script] = script
      timeout = Travis::Build::Data::DEFAULTS[:timeouts][script.to_sym]
      assert = %w(before_install install before_script).include?(script)
      should run script, echo: true, log: true, assert: assert, timeout: timeout
    end
  end
end
