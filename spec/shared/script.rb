shared_examples_for 'a build script' do
  it_behaves_like 'a git repo'

  it_behaves_like "a script with env vars" do
    let(:env_type) { 'env' }
  end

  it_behaves_like "a script with env vars" do
    let(:env_type) { 'global_env' }
  end

  it 'sets TRAVIS_* env vars' do
    data['config']['env'].delete_if { |var| var =~ /SECURE / }

    should set 'TRAVIS_PULL_REQUEST',    'false'
    should set 'TRAVIS_SECURE_ENV_VARS', 'false'
    should set 'TRAVIS_BUILD_ID',        '1'
    should set 'TRAVIS_BUILD_NUMBER',    '1'
    should set 'TRAVIS_BUILD_DIR',       "#{Travis::Build::BUILD_DIR}/travis-ci/travis-ci"
    should set 'TRAVIS_JOB_ID',          '1'
    should set 'TRAVIS_JOB_NUMBER',      '1.1'
    should set 'TRAVIS_BRANCH',          'master'
    should set 'TRAVIS_COMMIT',          '313f61b'
    should set 'TRAVIS_COMMIT_RANGE',    '313f61b..313f61a'
    should set 'TRAVIS_REPO_SLUG',       'travis-ci/travis-ci'
  end

  it 'sets TRAVIS_PULL_REQUEST to the given number when running a pull_request' do
    data['job']['pull_request'] = 1
    should set 'TRAVIS_PULL_REQUEST', '1'
    store_example 'pull_request' if described_class == Travis::Build::Script::Generic
  end

  it 'sets TRAVIS_TEST_RESULT to 0 if all scripts exited with 0' do
    data['config']['script'] = ['true', 'true', 'true', 'true']
    should set 'TRAVIS_TEST_RESULT', 0
  end

  it 'sets TRAVIS_TEST_RESULT to 1 if any command exited with 1' do
    data['config']['script'] = ['false', 'true', 'false', 'true']
    should set 'TRAVIS_TEST_RESULT', 1
  end

  # TODO after_failure won't be called because the build script never returns 1
  %w(before_install install before_script script after_script after_success).each do |script|
    it "runs the given :#{script} command" do
      data['config'][script] = script
      timeout = Travis::Build::Data::DEFAULTS[:timeouts][script.to_sym]
      assert = %w(before_install install before_script).include?(script)
      should run script, echo: true, log: true, assert: assert, timeout: timeout
    end

    next if script == 'script'

    it "adds fold markers for each of the :#{script} commands" do
      data['config'][script] = [script, script]
      should fold script, "#{script}.1"
      should fold script, "#{script}.2"
    end
  end
end
