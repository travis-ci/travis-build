shared_examples_for 'a git repo sexp' do
  describe 'using tarball' do
    let(:api)  { 'https://api.github.com/repos/travis-ci/travis-ci' }
    let(:url)  { "#{api}/tarball/313f61b" }
    let(:file) { 'travis-ci-travis-ci.tar.gz' }

    before :each do
      data['config']['git'] = { strategy: 'tarball' }
      data['repository']['api_url'] = api
    end

    it 'creates the directory structure' do
      cmd = 'mkdir -p travis-ci/travis-ci'
      should include_sexp [:cmd, cmd, timing: true]
    end

    it 'downloads the tarball from github' do
      cmd = "curl -o #{file} -L #{url}"
      sexp = sexp_fold('tarball.1', [:cmd, cmd, assert: true, echo: cmd, retry: true, timing: true])
      should include_sexp sexp
    end

    it 'untars the tarball' do
      cmd = "tar xfz #{file}"
      should include_sexp [:cmd, cmd, assert: true, echo: true, timing: true]
    end

    it 'corrects the directory structure' do
      cmd = 'mv travis-ci-travis-ci-313f61b/* travis-ci/travis-ci'
      should include_sexp [:cmd, cmd, assert: true, timing: true]
    end

    it 'changes to the correct directory' do
      should include_sexp [:cd, 'travis-ci/travis-ci', echo: true]
    end

    describe 'with a token' do
      let(:token) { 'foobar' }

      before do
        data['oauth_token'] = token
      end

      it 'downloads with the token, but does not print it' do
        cmd  = "curl -o #{file} -H \"Authorization: token #{token}\" -L #{url}"
        echo = "curl -o #{file} -H \"Authorization: token [SECURE]\" -L #{url}"
        should include_sexp [:cmd, cmd, assert: true, echo: echo, retry: true, timing: true]
      end
    end

    context "with a custom api_endpoint" do
      let(:api) { 'https://foo.bar.baz/api/repos/travis-ci/travis-ci' }

      it 'downloads the tarball from the custom endpoint' do
        cmd = "curl -o #{file} -L #{url}"
        should include_sexp [:cmd, cmd, assert: true, echo: cmd, retry: true, timing: true]
      end
    end
  end

  describe 'using clone' do
    let(:url)    { 'git://github.com/travis-ci/travis-ci.git' }
    let(:dir)    { 'travis-ci/travis-ci' }
    let(:branch) { data['job']['branch'] || 'master' }
    let(:depth)  { data['config']['git']['depth'] || 50 }

    before :each do
      data['config']['git'] = { strategy: 'clone' }
    end

    describe 'when the repository is cloned not yet' do
      let(:cmd) { "git clone --depth=#{depth} --branch=#{branch.shellescape} #{url} #{dir}" }

      it 'clones the git repo' do
        should include_sexp [:cmd, cmd, assert: true, echo: true, retry: true, timing: true]
      end

      it 'clones with a custom depth' do
        data['config']['git']['depth'] = 1
        should include_sexp [:cmd, cmd, assert: true, echo: true, retry: true, timing: true]
      end

      it 'escapes the branch name' do
        data['job']['branch'] = 'foo->bar'
        should include_sexp [:cmd, cmd, assert: true, echo: true, retry: true, timing: true]
      end
    end

    describe 'when the repository is already cloned' do
      let(:sexp) { sexp_find(subject, [:if, '! -d travis-ci/travis-ci/.git'], [:else]) }

      it 'fetches the changes' do
        expect(sexp).to include_sexp [:cmd, 'git fetch origin', assert: true, echo: true, retry: true, timing: true]
      end
    end

    it 'changes to the git repo dir' do
      should include_sexp [:cd, 'travis-ci/travis-ci', echo: true]
    end

    it 'does not fetch a ref if not given' do
      cmd = 'git fetch origin'
      should include_sexp [:cmd, cmd, assert: true, echo: true, retry: true, timing: true]
    end

    it 'fetches a ref if given' do
      data['job']['ref'] = 'refs/pull/118/merge'
      cmd = 'git fetch origin +refs/pull/118/merge:'
      should include_sexp [:cmd, cmd, assert: true, echo: true, retry: true, timing: true]
    end

    it 'removes the ssh key' do
      should include_sexp [:rm, '~/.ssh/source_rsa', force: true]
    end

    it 'checks out the given commit for a push request' do
      data['job']['pull_request'] = false
      sexp = sexp_fold('git.1', [:cmd, 'git checkout -qf 313f61b', assert: true, echo: true, timing: true])
      should include_sexp sexp
    end

    it 'checks out FETCH_HEAD for a pull request' do
      data['job']['pull_request'] = true
      should include_sexp [:cmd, 'git checkout -qf FETCH_HEAD', assert: true, echo: true, timing: true]
    end

    describe 'submodules' do
      let(:sexp) { sexp_find(subject, [:if, '-f .gitmodules'], [:then]) }

      let(:submodule_init)   { [:cmd, 'git submodule init', assert: true, echo: true, timing: true] }
      let(:submodule_update) { [:cmd, 'git submodule update', assert: true, echo: true, retry: true, timing: true] }

      describe 'if .gitmodules exists' do
        it { should include_sexp submodule_init }
        it { should include_sexp submodule_update }
      end

      describe 'submodules is set to false' do
        before { data['config']['git'] = { submodules: false } }

        it { expect(sexp_find(subject, submodule_init)).to be_nil }
        it { expect(sexp_find(subject, submodule_update)).to be_nil }
      end
    end
  end

  let(:source_key)      { "d2hvbGV0dGhlam9zaG91dA==\n" }
  let(:known_hosts)     { "Host github.com\n\tBatchMode yes\n\tStrictHostKeyChecking no\n" }

  let(:add_source_key)  { [:file, [source_key, '~/.ssh/id_rsa'], decode: true] }
  let(:chmod_id_rsa)    { [:chmod, [600, '~/.ssh/id_rsa']] }
  let(:start_ssh_agent) { [:cmd, 'eval `ssh-agent` &> /dev/null', timing: true] }
  let(:add_ssh_key)     { [:cmd, 'ssh-add ~/.ssh/id_rsa &> /dev/null', timing: true] }
  let(:add_known_hosts) { [:file, ['~/.ssh/config', known_hosts], append: true] }

  describe 'there is a source_key' do
    before :each do
      data['config']['source_key'] = source_key
    end

    it { should include_sexp add_source_key }
    it { should include_sexp chmod_id_rsa }
    it { should include_sexp start_ssh_agent }
    it { should include_sexp add_ssh_key }
    it { should include_sexp add_known_hosts }
  end

  describe 'there is no source_key' do
    it { expect(sexp_find(subject, add_source_key)).to be_nil }
    it { expect(sexp_find(subject, chmod_id_rsa)).to be_nil }
    it { expect(sexp_find(subject, start_ssh_agent)).to be_nil }
    it { expect(sexp_find(subject, add_ssh_key)).to be_nil }
    it { expect(sexp_find(subject, add_known_hosts)).to be_nil }
  end
end

