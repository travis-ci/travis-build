shared_examples_for 'a git repo' do
  describe 'using tarball' do
    before :each do
      data['config']['git'] = { strategy: 'tarball' }
      data['repository']['api_url'] = "https://api.github.com/repos/travis-ci/travis-ci"
    end

    it 'creates the directory structure' do
      cmd = 'mkdir -p travis-ci/travis-ci'
      should run cmd, echo: true, assert: true
    end

    it 'downloads the tarball from github' do
      cmd = 'curl -o travis-ci-travis-ci.tar.gz -L https://api.github.com/repos/travis-ci/travis-ci/tarball/313f61b'
      should run cmd, echo: true, assert: true, retry: true, fold: "tarball.1"
    end

    it 'untars the tarball' do
      cmd = 'tar xfz travis-ci-travis-ci.tar.gz'
      should run cmd, echo: true, assert: true
    end

    it 'corrects the directory structure' do
      cmd = 'mv travis-ci-travis-ci-313f61b/* travis-ci/travis-ci'
      should run cmd, echo: true, assert: true
    end

    it 'changes to the correct directory' do
      cmd = 'cd travis-ci/travis-ci'
      should run cmd, echo: true, assert: true
    end

    context "with a token" do
      before do
        data['oauth_token'] = 'foobarbaz'
      end

      it "downloads using token" do
        cmd = 'curl -o travis-ci-travis-ci.tar.gz -H "Authorization: token foobarbaz" -L https://api.github.com/repos/travis-ci/travis-ci/tarball/313f61b'
        subject.should include(cmd)
      end

      it "does not print token" do
        cmd = 'curl -o travis-ci-travis-ci.tar.gz -H "Authorization: token [SECURE]" -L https://api.github.com/repos/travis-ci/travis-ci/tarball/313f61b'
        subject.should include(cmd.shellescape)
      end
    end

    context "with a custom api_endpoint" do
      before do
        data['repository']['api_url'] = 'https://foo.bar.baz/api/repos/travis-ci/travis-ci'
      end

      it 'downloads the tarball from the custom endpoint' do
        cmd = 'curl -o travis-ci-travis-ci.tar.gz -L https://foo.bar.baz/api/repos/travis-ci/travis-ci/tarball/313f61b'
        should run cmd, echo: true, assert: true, retry: true, fold: "tarball.1"
      end
    end
  end

  describe 'using clone' do
    before :each do
      data['config']['git'] = { strategy: 'clone' }
    end

    it 'clones the git repo' do
      cmd = 'git clone --depth=50 --branch=master git://github.com/travis-ci/travis-ci.git travis-ci/travis-ci'
      timeout = Travis::Build::Data::DEFAULTS[:timeouts][:git_clone]
      should run cmd, echo: true, log: true, assert: true, timeout: timeout, retry: true
    end

    it 'clones with a custom depth if given' do
      data['config']['git'] = { depth: 1 }
      cmd = 'git clone --depth=1 --branch=master git://github.com/travis-ci/travis-ci.git travis-ci/travis-ci'
      should run cmd, echo: true
    end

    it 'escapes the branch name if necessary' do
      data['job']['branch'] = 'a->b'
      cmd = "git clone --depth=50 --branch=a-\>b"
      should run cmd
    end

    context 'when the repository is already cloned' do
      before do
        directory 'travis-ci/travis-ci/.git'
      end

      it 'does not clone again' do
        should_not run 'git clone'
      end

      it 'fetches the changes' do
        should run 'git fetch'
      end
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

    it 'checks out the given commit for a push request' do
      data['job']['pull_request'] = false
      should run 'git checkout -qf 313f61b', echo: true, log: true
    end

    it 'checks out FETCH_HEAD for a pull request' do
      data['job']['pull_request'] = true
      should run 'git checkout -qf FETCH_HEAD', echo: true, log: true
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
