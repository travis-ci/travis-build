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
    should set 'TRAVIS_BUILD_DIR',       "#{Travis::Build::BUILD_DIR}/travis-ci/travis-ci" unless described_class == Travis::Build::Script::Go
    should set 'TRAVIS_JOB_ID',          '1'
    should set 'TRAVIS_JOB_NUMBER',      '1.1'
    should set 'TRAVIS_BRANCH',          'master'
    should set 'TRAVIS_COMMIT',          '313f61b'
    should set 'TRAVIS_COMMIT_RANGE',    '313f61b..313f61a'
    should set 'TRAVIS_REPO_SLUG',       'travis-ci/travis-ci'
    should set 'TRAVIS_OS_NAME',         'linux'
  end

  it "sets PS4 to fix an rvm issue" do
    subject.should include("export PS4=+ ")
  end

  it 'sets TRAVIS_PULL_REQUEST to the given number when running a pull_request' do
    data['job']['pull_request'] = 1
    data['job']['secure_env_enabled'] = false
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

  it "sets up an apt cache if the option is enabled" do
    data['config']['cache'] = ['apt']
    data['hosts']= {'apt_cache' => 'http://cache.example.com:80'}
    subject.should include(%Q{echo 'Acquire::http { Proxy "http://cache.example.com:80"; };' | sudo -n tee /etc/apt/apt.conf.d/01proxy})
  end

  it "doesn't set up an apt cache when the cache list is empty" do
    data['hosts'] = {'apt_cache' => 'http://cache.example.com:80'}
    subject.should_not include(%Q{echo 'Acquire::http { Proxy "http://cache.example.com:80"; };' | sudo -n tee /etc/apt/apt.conf.d/01proxy})
  end

  it "doesn't set up an apt cache when the host isn't set" do
    data['config']['cache'] = ['apt']
    data['hosts'] = nil
    subject.should_not include(%Q{echo 'Acquire::http { Proxy "http://cache.example.com:80"; };' | sudo -n tee /etc/apt/apt.conf.d/01proxy})
  end

  describe 'disallow_sudo_access' do
    it "removes sudo access if :disallow_sudo was given as an option" do
      options.merge! disallow_sudo: true
      subject.should include(%Q{sudo -n rm -f /etc/sudoers.d/travis})
    end

    it "removes sudo access if 'disallow_sudo' was given via payload" do
      data['disallow_sudo'] = true
      subject.should include(%Q{sudo -n rm -f /etc/sudoers.d/travis})
    end

    it "does not remove sudo access by default" do
      subject.should_not include(%Q{sudo -n rm -f /etc/sudoers.d/travis})
    end
  end

  describe 'fix_resolv_conf' do
    it "fixes the DNS entries in /etc/resolv.conf" do
      subject.should include('| sudo -n tee /etc/resolv.conf &> /dev/null')
    end

    it "skips fixing the DNS entries in /etc/resolv.conf if :skip_resolve_updates was given as an option" do
      options.merge! skip_resolv_updates: true
      subject.should_not include('| sudo -n tee /etc/resolv.conf &> /dev/null')
    end

    it "skips fixing the DNS entries in /etc/resolv.conf if 'skip_resolve_updates' was given via payload" do
      data['skip_resolv_updates'] = true
      subject.should_not include('| sudo -n tee /etc/resolv.conf &> /dev/null')
    end
  end

  describe 'fix_etc_hosts' do
    it "adds an entry to /etc/hosts for localhost" do
      subject.should include(%Q{sudo -n sed -e 's/^\\(127\\.0\\.0\\.1.*\\)$/\\1 '`hostname`'/' -i.bak /etc/hosts})
    end

    it "skips adding an entry to /etc/hosts if :skip_etc_hosts_fix was given as an option" do
      options.merge! skip_etc_hosts_fix: true
      subject.should_not include(%Q{sudo -n sed -e 's/^\\(127\\.0\\.0\\.1.*\\)$/\\1 '`hostname`'/' -i.bak /etc/hosts})
    end

    it "skips adding an entry to /etc/hosts if 'skip_resolve_updates' was given via payload" do
      data['skip_etc_hosts_fix'] = true
      subject.should_not include(%Q{sudo -n sed -e 's/^\\(127\\.0\\.0\\.1.*\\)$/\\1 '`hostname`'/' -i.bak /etc/hosts})
    end
  end


  it "fixes NPM's certificate chain" do
    subject.should include(%Q{npm config set ca ""})
  end

  describe "result" do
    before do
      data['config']['.result'] = result
      data['config']['script'] = 'echo "THE SCIPT"'
    end

    describe "server error" do
      let(:result) { "server_error" }
      it { should include("echo -e \"\\033[31;1mCould not fetch .travis.yml from GitHub.\\033[0m\"\ntravis_terminate 2") }
      it { should_not include('echo "THE SCIPT"') }
    end

    describe "not found" do
      let(:result) { "not_found" }
      it { should include("echo -e \"\\033[31;1mCould not find .travis.yml, using standard configuration.\\033[0m\"") }
      it { should include('echo "THE SCIPT"') }
    end
  end
end
