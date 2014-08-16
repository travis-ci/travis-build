require "pathname"

shared_examples_for 'a git repo' do
  describe 'using tarball' do
    before :each do
      data['config']['git'] = { strategy: 'tarball' }
      data['repository']['api_url'] = "https://api.github.com/repos/travis-ci/travis-ci"
    end

    it 'creates the directory structure' do
      cmd = 'mkdir -p travis-ci/travis-ci'
      is_expected.to travis_cmd cmd
    end

    it 'downloads the tarball from github' do
      cmd = 'curl -o travis-ci-travis-ci.tar.gz -L https://api.github.com/repos/travis-ci/travis-ci/tarball/313f61b'
      is_expected.to travis_cmd cmd, echo: cmd, assert: true, retry: true, timing: true, fold: "tarball.1"
    end

    it 'untars the tarball' do
      cmd = 'tar xfz travis-ci-travis-ci.tar.gz'
      is_expected.to travis_cmd cmd, echo: true, assert: true, timing: true
    end

    it 'corrects the directory structure' do
      cmd = 'mv travis-ci-travis-ci-313f61b/* travis-ci/travis-ci'
      is_expected.to travis_cmd cmd, echo: true, assert: true, timing: true
    end

    it 'changes to the correct directory' do
      cmd = 'cd travis-ci/travis-ci'
      is_expected.to travis_cmd cmd, echo: true
    end

    context "with a token" do
      before do
        data['oauth_token'] = 'foobarbaz'
      end

      it "downloads using token" do
        cmd = 'travis_cmd curl\ -o\ travis-ci-travis-ci.tar.gz\ -H\ \"Authorization:\ token\ foobarbaz\"'
        expect(subject).to include(cmd)
      end

      it "does not print token" do
        cmd = 'curl -o travis-ci-travis-ci.tar.gz -H "Authorization: token [SECURE]" -L https://api.github.com/repos/travis-ci/travis-ci/tarball/313f61b'
        expect(subject).to include(cmd.shellescape)
      end
    end

    context "with a custom api_endpoint" do
      before do
        data['repository']['api_url'] = 'https://foo.bar.baz/api/repos/travis-ci/travis-ci'
      end

      it 'downloads the tarball from the custom endpoint' do
        cmd = 'curl -o travis-ci-travis-ci.tar.gz -L https://foo.bar.baz/api/repos/travis-ci/travis-ci/tarball/313f61b'
        is_expected.to travis_cmd cmd, echo: cmd, assert: true, retry: true, timing: true, fold: "tarball.1"
      end
    end
  end

  describe 'using clone' do
    before :each do
      data['config']['git'] = { strategy: 'clone' }
    end

    it 'clones the git repo' do
      cmd = 'git clone --depth=50 --branch=master git://github.com/travis-ci/travis-ci.git travis-ci/travis-ci'
      is_expected.to travis_cmd cmd, echo: true, assert: true, retry: true, timing: true
    end

    it 'clones with a custom depth if given' do
      data['config']['git'] = { depth: 1 }
      cmd = 'git clone --depth=1 --branch=master git://github.com/travis-ci/travis-ci.git travis-ci/travis-ci'
      is_expected.to travis_cmd cmd, echo: true, assert: true, retry: true, timing: true
    end

    it 'escapes the branch name if necessary' do
      data['job']['branch'] = 'a->b'
      cmd = "git clone --depth=50 --branch=a-\>b"
      expect(subject).to include('git\\ clone\\ --depth\\=50\\ --branch\\=a-\\\\\\>b')
    end

    context 'when the repository is already cloned' do
      before do
        directory 'travis-ci/travis-ci/.git'
      end

      it 'does not clone again' do
        is_expected.not_to run 'git\\ clone'
      end

      it 'fetches the changes' do
        is_expected.to travis_cmd 'git -C travis-ci/travis-ci fetch origin'
      end

      it 'resets repository' do
        is_expected.to travis_cmd 'git -C travis-ci/travis-ci reset --hard'
      end
    end

    it 'changes to the git repo dir' do
      is_expected.to travis_cmd 'cd travis-ci/travis-ci', echo: true
    end

    it 'does not fetch a ref if not given' do
      is_expected.not_to run 'git\\ fetch'
    end

    it 'fetches a ref if given' do
      data['job']['ref'] = 'refs/pull/118/merge'
      cmd = 'git fetch origin +refs/pull/118/merge:'
      is_expected.to travis_cmd cmd, echo: true, assert: true, timing: true, retry: true
    end

    it 'removes the ssh key' do
      is_expected.to run %r(rm -f .*\.ssh/source_rsa)
    end

    it 'checks out the given commit for a push request' do
      data['job']['pull_request'] = false
      is_expected.to travis_cmd 'git checkout -qf 313f61b', echo: true, assert: true
    end

    it 'checks out FETCH_HEAD for a pull request' do
      data['job']['pull_request'] = true
      is_expected.to travis_cmd 'git checkout -qf FETCH_HEAD', echo: true, assert: true
    end

    # this will trash your ~/.ssh/config
    # you should only be run on a clean room env
    describe 'if .gitmodules exists', clean_room: true do
      before :each do
        file '.gitmodules'
      end

      it 'inits submodules' do
        is_expected.to travis_cmd 'git submodule init'
      end


      context 'without setting submodules_depth' do
        it 'updates submodules with no depth' do
          is_expected.to travis_cmd 'git submodule update'
        end
      end

      context 'when setting submodules_depth' do
        before do
          data['config']['git'] = { submodules_depth: 50 }
        end

        it 'updates submodules with that depth' do
          is_expected.to travis_cmd 'git submodule update --depth=50'
        end
      end
    end

    describe 'submodules is set to false', clean_room: true do
      before :each do
        file '.gitmodules'
        data['config']['git'] = { submodules: false }
      end

      it 'does not init submodules' do
        is_expected.not_to run 'git submodule init'
      end

      it 'does not update submodules' do
        is_expected.not_to run 'git submodule update'
      end
    end
  end

  # this currently trashes your local ~/.ssh/id_rsa and known_hosts file
  # you should only be run on a clean room env
  describe 'there is a source_key', clean_room: true do
    before :each do
      data['config']['source_key'] = "d2hvbGV0dGhlam9zaG91dA==\n"
    end

    it 'does not add the source_key' do
      is_expected.to run /echo wholetthejoshout > ~\/.ssh\/id_rsa/
    end

    it 'does not change the id_rsa file permissions' do
      is_expected.to run "chmod 600 ~/.ssh/id_rsa"
    end

    it 'does not start the ssh-agent' do
      is_expected.to run "eval `ssh-agent` &>/dev/null"
    end

    it 'does not add the id_rsa key to the ssh agent' do
      is_expected.to run "ssh-add ~/.ssh/id_rsa &>/dev/null"
    end

    it 'does not add github.com to the known_hosts file' do
      is_expected.to run "echo -e \"Host github.com\n\tBatchMode yes\n\tStrictHostKeyChecking no\n\" >> ~/.ssh/config"
    end
  end

  describe 'there is no source_key' do
    it 'does not add the source_key' do
      is_expected.not_to run /> ~\/.ssh\/id_rsa/
    end

    it 'does not change the id_rsa file permissions' do
      is_expected.not_to run "chmod 600 ~/.ssh/id_rsa"
    end

    it 'does not start the ssh-agent' do
      is_expected.not_to run "eval `ssh-agent` &>/dev/null"
    end

    it 'does not add the id_rsa key to the ssh agent' do
      is_expected.not_to run "ssh-add ~/.ssh/id_rsa &>/dev/null"
    end

    it 'does not add github.com to the known_hosts file' do
      is_expected.not_to run "echo -e \"Host github.com\n\tBatchMode yes\n\tStrictHostKeyChecking no\n\" >> ~/.ssh/config"
    end
  end
end
