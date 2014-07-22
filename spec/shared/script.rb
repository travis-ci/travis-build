shared_examples_for 'a build script' do
  it_behaves_like 'a git repo'

  it_behaves_like "a script with env vars" do
    let(:env_type) { 'env' }
  end

  it_behaves_like "a script with env vars" do
    let(:env_type) { 'global_env' }
  end

  it 'announces setting environment variables from settings' do
    data['config']['env'] = nil
    data['config']['global_env'] = nil
    data['env_vars'] = [{ 'name' => 'SETTINGS_VAR', 'value' => 'a value', 'public' => false }]
    is_expected.to echo 'export SETTINGS_VAR=[secure]'
    is_expected.to run /Setting environment variables from repository settings/
    is_expected.not_to run /Setting environment variables from .travis.yml/
  end

  it 'announces setting environment variables from config' do
    data['config']['global_env'] = 'SECURE CONFIG_VAR=value'
    is_expected.to echo 'export CONFIG_VAR=[secure]'
    is_expected.not_to run /Setting environment variables from repository settings/
    is_expected.to run /Setting environment variables from .travis.yml/
  end

  it 'sets TRAVIS_* env vars' do
    data['config']['env'].delete_if { |var| var =~ /SECURE / }

    is_expected.to set 'TRAVIS_PULL_REQUEST',    'false'
    is_expected.to set 'TRAVIS_SECURE_ENV_VARS', 'false'
    is_expected.to set 'TRAVIS_BUILD_ID',        '1'
    is_expected.to set 'TRAVIS_BUILD_NUMBER',    '1'
    is_expected.to set 'TRAVIS_BUILD_DIR',       "#{Travis::Build::BUILD_DIR}/travis-ci/travis-ci" unless described_class == Travis::Build::Script::Go
    is_expected.to set 'TRAVIS_JOB_ID',          '1'
    is_expected.to set 'TRAVIS_JOB_NUMBER',      '1.1'
    is_expected.to set 'TRAVIS_BRANCH',          'master'
    is_expected.to set 'TRAVIS_COMMIT',          '313f61b'
    is_expected.to set 'TRAVIS_COMMIT_RANGE',    '313f61b..313f61a'
    is_expected.to set 'TRAVIS_REPO_SLUG',       'travis-ci/travis-ci'
    is_expected.to set 'TRAVIS_OS_NAME',         'linux'
  end

  it "sets PS4 to fix an rvm issue" do
    expect(subject).to include("export PS4=+ ")
  end

  it 'sets TRAVIS_PULL_REQUEST to the given number when running a pull_request' do
    data['job']['pull_request'] = 1
    data['job']['secure_env_enabled'] = false
    is_expected.to set 'TRAVIS_PULL_REQUEST', '1'
    store_example 'pull_request' if described_class == Travis::Build::Script::Generic
  end

  it 'sets TRAVIS_TEST_RESULT to 0 if all scripts exited with 0' do
    data['config']['script'] = ['true', 'true', 'true', 'true']
    is_expected.to set 'TRAVIS_TEST_RESULT', 0
  end

  it 'sets TRAVIS_TEST_RESULT to 1 if any command exited with 1' do
    data['config']['script'] = ['false', 'true', 'false', 'true']
    is_expected.to set 'TRAVIS_TEST_RESULT', 1
  end

  # TODO after_failure won't be called because the build script never returns 1
  %w(before_install install before_script script after_script after_success).each do |script|
    it "runs the given :#{script} command" do
      data['config'][script] = script
      assert = %w(before_install install before_script).include?(script)
      is_expected.to run script, echo: true, log: true, assert: assert
    end

    next if script == 'script'

    it "adds fold markers for each of the :#{script} commands" do
      data['config'][script] = [script, script]
      is_expected.to fold script, "#{script}.1"
      is_expected.to fold script, "#{script}.2"
    end
  end

  it "sets up an apt cache if the option is enabled" do
    data['config']['cache'] = ['apt']
    data['hosts']= {'apt_cache' => 'http://cache.example.com:80'}
    expect(subject).to include(%Q{echo 'Acquire::http { Proxy "http://cache.example.com:80"; };' | sudo tee /etc/apt/apt.conf.d/01proxy})
  end

  it "doesn't set up an apt cache when the cache list is empty" do
    data['hosts'] = {'apt_cache' => 'http://cache.example.com:80'}
    expect(subject).not_to include(%Q{echo 'Acquire::http { Proxy "http://cache.example.com:80"; };' | sudo tee /etc/apt/apt.conf.d/01proxy})
  end

  it "doesn't set up an apt cache when the host isn't set" do
    data['config']['cache'] = ['apt']
    data['hosts'] = nil
    expect(subject).not_to include(%Q{echo 'Acquire::http { Proxy "http://cache.example.com:80"; };' | sudo tee /etc/apt/apt.conf.d/01proxy})
  end

  it "fixed the DNS entries in /etc/resolv.conf" do
    expect(subject).to include(%Q{echo 'nameserver 199.91.168.70\nnameserver 199.91.168.71' | sudo tee /etc/resolv.conf &> /dev/null})
  end

  it "skips fixing the DNS entries in /etc/resolv.conf if told to" do
    data['skip_resolv_updates'] = true
    expect(subject).not_to include(%Q{echo 'nameserver 199.91.168.70\nnameserver 199.91.168.71' | sudo tee /etc/resolv.conf &> /dev/null})
  end

  it "adds an entry to /etc/hosts for localhost" do
    expect(subject).to include(%Q{sudo sed -e 's/^\\(127\\.0\\.0\\.1.*\\)$/\\1 '`hostname`'/' -i'.bak' /etc/hosts})
  end

  it "skips adding an entry to /etc/hosts for localhost" do
    data['skip_etc_hosts_fix'] = true
    expect(subject).not_to include(%Q{sudo sed -e 's/^\\(127\\.0\\.0\\.1.*\\)$/\\1 '`hostname`'/' -i'.bak' /etc/hosts})
  end

  # further specs for not allowing services should be added
  describe "paranoid mode" do
    it "does not remove access to sudo by default" do
      expect(subject).not_to include(%Q{sudo -n sh -c "sed -e 's/^%.*//' -i.bak /etc/sudoers && rm -f /etc/sudoers.d/travis && find / -perm -4000 -exec chmod a-s {} \\; 2>/dev/null"})
    end

    it "removes access to sudo if enabled in the config" do
      data['paranoid'] = true
      expect(subject).to include(%Q{sudo -n sh -c "sed -e 's/^%.*//' -i.bak /etc/sudoers && rm -f /etc/sudoers.d/travis && find / -perm -4000 -exec chmod a-s {} \\; 2>/dev/null"})
    end
  end

  describe "result" do
    before do
      data['config']['.result'] = result
      data['config']['script'] = 'echo "THE SCIPT"'
    end

    describe "server error" do
      let(:result) { "server_error" }
      it { is_expected.to include("echo -e \"\\033[31;1mCould not fetch .travis.yml from GitHub.\\033[0m\"\ntravis_terminate 2") }
      it { is_expected.not_to include('echo "THE SCIPT"') }
    end

    describe "not found" do
      let(:result) { "not_found" }
      it { is_expected.to include("echo -e \"\\033[31;1mCould not find .travis.yml, using standard configuration.\\033[0m\"") }
      it { is_expected.to include('echo "THE SCIPT"') }
    end
  end
end
