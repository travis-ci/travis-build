shared_examples_for 'a build script' do
  it_behaves_like 'a git repo'

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

  it 'sets TRAVIS_PULL_REQUEST to the given number when running a pull_request' do
    data['job']['pull_request'] = 1
    should set 'TRAVIS_PULL_REQUEST', '1'
    store_example 'pull_request' if described_class == Travis::Build::Script::Generic
  end

  it 'sets TRAVIS_SECURE_ENV_VARS to true when using secure env vars' do
    data['config']['env'] = 'SECURE BAR=bar'
    should set 'TRAVIS_SECURE_ENV_VARS', 'true'
    store_example 'secure_var' if described_class == Travis::Build::Script::Generic
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

  it 'does not set secure :env vars on pull requests' do
    data['job']['pull_request'] = 1
    data['config']['env'] = 'SECURE BAR=bar'
    should_not set 'BAR', 'bar'
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
