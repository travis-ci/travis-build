shared_examples_for 'compiled script' do
  include SpecHelpers::Shell

  subject { Travis::Build.script(data).compile }

  it 'can be compiled' do
    expect { subject }.to_not raise_error
  end

  it 'includes the expected shell code' do
    code.each do |code|
      should include_shell code
    end
  end
end

shared_examples_for 'a build script sexp' do
  it_behaves_like 'a git repo sexp'

  it_behaves_like 'a script with env vars sexp' do
    let(:env_type) { 'env' }
  end

  it_behaves_like 'a script with env vars sexp' do
    let(:env_type) { 'global_env' }
  end

  it 'sets environment variables from settings' do
    data[:config][:env] = nil
    data[:config][:global_env] = nil
    data[:env_vars] = ['name' => 'SETTINGS_VAR', 'value' => 'value', 'public' => false]

    should include_sexp [:export, ['SETTINGS_VAR', 'value'], echo: true, secure: true]
    should include_sexp [:echo, 'Setting environment variables from repository settings', ansi: :yellow]
    should_not include_sexp [:echo, 'Setting environment variables from .travis.yml', ansi: :yellow]
  end

  it 'sets environment variables from config' do
    data[:config][:global_env] = 'SECURE CONFIG_VAR=value'
    should include_sexp [:export, ['CONFIG_VAR', 'value'], echo: true, secure: true]
    should_not include_sexp [:echo, 'Setting environment variables from repository settings', ansi: :yellow]
    should include_sexp [:echo, 'Setting environment variables from .travis.yml', ansi: :yellow]
    should include_sexp [:export, ['TRAVIS_SECURE_ENV_VARS', 'true']]
  end

  it 'sets TRAVIS_* env vars' do
    data[:config][:env].delete_if { |var| var =~ /SECURE / }

    should include_sexp [:export, ['TRAVIS_PULL_REQUEST',    'false']]
    should include_sexp [:export, ['TRAVIS_SECURE_ENV_VARS', 'false']]
    should include_sexp [:export, ['TRAVIS_BUILD_ID',        '1']]
    should include_sexp [:export, ['TRAVIS_BUILD_NUMBER',    '1']]
    should include_sexp [:export, ['TRAVIS_JOB_ID',          '1']]
    should include_sexp [:export, ['TRAVIS_JOB_NUMBER',      '1.1']]
    should include_sexp [:export, ['TRAVIS_BRANCH',          'master']]
    should include_sexp [:export, ['TRAVIS_COMMIT',          '313f61b']]
    should include_sexp [:export, ['TRAVIS_COMMIT_RANGE',    '313f61b..313f61a']]
    should include_sexp [:export, ['TRAVIS_REPO_SLUG',       'travis-ci/travis-ci']]
    should include_sexp [:export, ['TRAVIS_OS_NAME',         'linux']]
    should include_sexp [:export, ['TRAVIS_LANGUAGE',        data[:config][:language].to_s]]

    unless described_class == Travis::Build::Script::Go
      should include_sexp [:export, ['TRAVIS_BUILD_DIR', "#{Travis::Build::BUILD_DIR}/travis-ci/travis-ci"]]
    end
  end

  it 'sets PS4 to fix an rvm issue' do
    should include_sexp [:export, ['PS4', '+ ']]
  end

  it 'sets TRAVIS_PULL_REQUEST to the given number when running a pull_request' do
    data[:job][:pull_request] = 1
    data[:job][:secure_env_enabled] = false
    should include_sexp [:export, ['TRAVIS_PULL_REQUEST', '1']]
  end

  it 'calls travis_result' do
    should include_sexp [:raw, 'travis_result $?']
  end

  %w(before_install install before_script script after_script after_success).each do |script|
    it "runs the given :#{script} command", focus: script == 'after_success' do
      data[:config][script] = script
      assert = %w(before_install install before_script).include?(script)
      options = { assert: assert, echo: true, timing: true }.select { |_, value| value }
      should include_sexp [:cmd, script, options]
    end

    next if script == 'script'

    it "adds fold markers for each of the :#{script} commands" do
      data[:config][script] = [script, script]
      expect(!!sexp_find(subject, [:fold, "#{script}.2"])).to eql(true)
    end
  end

  describe 'apt cache setup' do
    let(:setup_apt_cache) { %(echo 'Acquire::http { Proxy "http://cache.example.com:80"; };' | sudo tee /etc/apt/apt.conf.d/01proxy &> /dev/null) }

    it 'sets up an apt cache if the option is enabled' do
      data[:config][:cache] = ['apt']
      data[:hosts]= { apt_cache: 'http://cache.example.com:80'}
      should include_sexp [:cmd, setup_apt_cache]
    end

    it "doesn't set up an apt cache when the cache list is empty" do
      data[:hosts]= { apt_cache: 'http://cache.example.com:80'}
      should_not include_sexp [:cmd, setup_apt_cache]
    end

    it "doesn't set up an apt cache when the host isn't set" do
      data[:config][:cache] = ['apt']
      data[:hosts] = nil
      should_not include_sexp [:cmd, setup_apt_cache]
    end
  end

  describe 'resolv.conf fix', focus: true do
    let(:fix_resolv_conf) { "grep '199.91.168' /etc/resolv.conf > /dev/null || echo 'nameserver 199.91.168.70\nnameserver 199.91.168.71' | sudo tee /etc/resolv.conf &> /dev/null" }

    it 'fixes the DNS entries in /etc/resolv.conf' do
      should include_sexp [:cmd, fix_resolv_conf]
    end

    it 'skips fixing the DNS entries in /etc/resolv.conf if told to' do
      data[:skip_resolv_updates] = true
      should_not include_sexp [:cmd, fix_resolv_conf]
    end
  end

  describe 'etc/hosts fix' do
    let(:fix_etc_hosts) { "sudo sed -e 's/^\\(127\\.0\\.0\\.1.*\\)$/\\1 '`hostname`'/' -i'.bak' /etc/hosts" }

    it 'adds an entry to /etc/hosts for localhost' do
      should include_sexp [:cmd, fix_etc_hosts]
    end

    it 'skips adding an entry to /etc/hosts for localhost' do
      data[:skip_etc_hosts_fix] = true
      should_not include_sexp [:cmd, fix_etc_hosts]
    end
  end

  # further specs for not allowing services should be added
  describe 'paranoid mode' do
    let(:remove_sudo) { %(sudo -n sh -c "sed -e 's/^%.*//' -i.bak /etc/sudoers && rm -f /etc/sudoers.d/travis && find / -perm -4000 -exec chmod a-s {} \\; 2>/dev/null") }

    it 'does not remove access to sudo by default' do
      should_not include_sexp [:cmd, remove_sudo]
    end

    it 'removes access to sudo if enabled in the config' do
      data[:paranoid] = true
      should include_sexp [:cmd, remove_sudo]
    end
  end

  describe 'config result' do
    let(:fetch_error)    { [:echo, 'Could not fetch .travis.yml from GitHub.', ansi: :red] }
    let(:missing_config) { [:echo, 'Could not find .travis.yml, using standard configuration.', ansi: :red] }
    let(:terminate)      { [:raw, 'travis_terminate 2'] }
    let(:run_script)     { [:cmd, './the_script', echo: true, timing: true] }

    before do
      data[:config][:'.result'] = result
      data[:config][:script] = './the_script'
    end

    describe 'server error' do
      let(:result) { 'server_error' }
      it { should include_sexp fetch_error }
      it { should include_sexp terminate }
      it { should_not include_sexp run_script }
    end

    describe 'not found' do
      let(:result) { 'not_found' }
      it { should include_sexp missing_config }
      it { should_not include_sexp terminate }
      it { should include_sexp run_script }
    end
  end
end
