shared_examples_for 'a build script' do
  it 'clones the git repo' do
    cmd = 'git clone --depth=100 --quiet git://github.com/travis-ci/travis-ci.git travis-ci/travis-ci'
    timeout = Travis::Build::Config::DEFAULTS[:timeouts][:git_clone]
    should run cmd, echo: true, log: true, assert: true, timeout: timeout
  end

  it 'does not fetch a ref if not given' do
    should_not run 'git fetch'
  end

  it 'fetches a ref if given' do
    config['job']['ref'] = 'refs/pull/118/merge'
    cmd = 'git fetch origin +refs/pull/118/merge:'
    timeout = Travis::Build::Config::DEFAULTS[:timeouts][:git_fetch_ref]
    should run cmd, echo: true, log: true, assert: true, timeout: timeout
  end

  it 'checks the given commit out' do
    should run 'git checkout -qf 313f61b', echo: true, log: true
  end

  it 'removes the ssh key' do
    should run %r(rm -f .*\.ssh/source_rsa)
  end

  it 'changes to the repo dir' do
    should run 'cd travis-ci/travis-ci', echo: true
  end

  it 'sets the given :env var' do
    config['config']['env'] = 'ENV=foo'
    should set 'ENV', 'foo'
  end

  # TODO after_failure won't be called because the build script never returns 1
  %w(before_install install before_script script after_script after_success).each do |script|
    it "runs the given :#{script} script" do
      config['config'][script] = script
      timeout = Travis::Build::Config::DEFAULTS[:timeouts][script.to_sym]
      assert = %w(before_install install before_script).include?(script)
      should run script, echo: true, log: true, assert: assert, timeout: timeout
    end
  end
end
