shared_examples_for 'a git repo' do
  it 'clones the git repo' do
    cmd = 'git clone --depth=100 --quiet --branch=master git://github.com/travis-ci/travis-ci.git travis-ci/travis-ci'
    timeout = Travis::Build::Data::DEFAULTS[:timeouts][:git_clone]
    should run cmd, echo: true, log: true, assert: true, timeout: timeout
  end

  it 'clones with a custom depth if given' do
    data['config']['git'] = { depth: 1 }
    cmd = 'git clone --depth=1 --quiet --branch=master git://github.com/travis-ci/travis-ci.git travis-ci/travis-ci'
    should run cmd, echo: true
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

  # TODO this currently trashes my ~/.ssh/config
  # describe 'if .gitmodules exists' do
  #   before :each do
  #     file '.gitmodules'
  #   end

  #   it 'inits submodules' do
  #     should run 'git submodule init'
  #   end

  #   it 'updates submodules' do
  #     should run 'git submodule update'
  #   end
  # end

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

  # TODO this currently trashes your local ~/.ssh/id_rsa and known_hosts file
  # describe 'there is a source_key' do
  #   before :each do
  #     data['config']['source_key'] = "d2hvbGV0dGhlam9zaG91dA==\n"
  #   end
  #
  #   it 'does not add the source_key' do
  #     should run /echo '\w+' | base64 -D -o ~\/.ssh\/id_rsa/
  #   end
  #
  #   it 'does not change the id_rsa file permissions' do
  #     should run "chmod 600 ~/.ssh/id_rsa"
  #   end
  #
  #   it 'does not start the ssh-agent' do
  #     should run "eval `ssh-agent` > /dev/null 2>&1"
  #   end
  #
  #   it 'does not add the id_rsa key to the ssh agent' do
  #     should run "ssh-add ~/.ssh/id_rsa > /dev/null 2>&1"
  #   end
  #
  #   it 'does not add github.com to the known_hosts file' do
  #     should run "echo -e \"Host github.com\n\tBatchMode yes\n\tStrictHostKeyChecking no\n\" >> ~/.ssh/config"
  #   end
  # end

  describe 'there is no source_key' do
    it 'does not add the source_key' do
      should_not run /echo '\w+' | base64 -D -o ~\/.ssh\/id_rsa/
    end

    it 'does not change the id_rsa file permissions' do
      should_not run "chmod 600 ~/.ssh/id_rsa"
    end

    it 'does not start the ssh-agent' do
      should_not run "eval `ssh-agent` > /dev/null 2>&1"
    end

    it 'does not add the id_rsa key to the ssh agent' do
      should_not run "ssh-add ~/.ssh/id_rsa > /dev/null 2>&1"
    end

    it 'does not add github.com to the known_hosts file' do
      should_not run "echo -e \"Host github.com\n\tBatchMode yes\n\tStrictHostKeyChecking no\n\" >> ~/.ssh/config"
    end
  end
end
