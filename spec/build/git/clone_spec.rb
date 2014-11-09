require 'spec_helper'

describe Travis::Build::Git::Clone, :sexp do
  let(:payload) { payload_for(:push, :ruby) }
  let(:script)  { Travis::Build::Script.new(payload) }
  subject       { script.sexp }

  let(:url)    { 'git://github.com/travis-ci/travis-ci.git' }
  let(:dir)    { 'travis-ci/travis-ci' }
  let(:branch) { payload[:job][:branch] || 'master' }
  let(:depth)  { payload[:config][:git]['depth'] || 50 }

  before :each do
    payload[:config][:git] = { strategy: 'clone' }
  end

  describe 'when the repository is cloned not yet' do
    let(:sexp) { sexp_find(subject, [:if, "! -d #{dir}/.git"]) }
    let(:cmd) { "git clone --depth=#{depth} --branch=#{branch.shellescape} #{url} #{dir}" }

    it 'clones the git repo' do
      should include_sexp [:cmd, cmd, assert: true, echo: true, retry: true, timing: true]
    end

    it 'clones with a custom depth' do
      payload[:config][:git]['depth'] = 1
      should include_sexp [:cmd, cmd, assert: true, echo: true, retry: true, timing: true]
    end

    it 'escapes the branch name' do
      payload[:job][:branch] = 'foo->bar'
      should include_sexp [:cmd, cmd, assert: true, echo: true, retry: true, timing: true]
    end
  end

  describe 'when the repository is already cloned' do
    let(:sexp) { sexp_find(subject, [:if, "! -d #{dir}/.git"], [:else]) }

    it 'fetches the changes' do
      cmd = 'git -C travis-ci/travis-ci fetch origin'
      expect(sexp).to include_sexp [:cmd, cmd, assert: true, echo: true, retry: true, timing: true]
    end

    it 'resets the repository' do
      cmd = 'git -C travis-ci/travis-ci reset --hard'
      expect(sexp).to include_sexp [:cmd, cmd, assert: true, echo: true]
    end

    it 'changes to the git repo dir' do
      should include_sexp [:cd, 'travis-ci/travis-ci', echo: true]
    end

    it 'does not fetch a ref if not given' do
      cmd = 'git -C travis-ci/travis-ci fetch origin'
      should include_sexp [:cmd, cmd, assert: true, echo: true, retry: true, timing: true]
    end

    it 'fetches a ref if given' do
      payload[:job][:ref] = 'refs/pull/118/merge'
      cmd = 'git fetch origin +refs/pull/118/merge:'
      should include_sexp [:cmd, cmd, assert: true, echo: true, retry: true, timing: true]
    end
  end

  it 'removes the ssh key' do
    should include_sexp [:rm, '~/.ssh/source_rsa', force: true]
  end

  it 'checks out the given commit for a push request' do
    payload[:job][:pull_request] = false
    should include_sexp [:cmd, 'git checkout -qf 313f61b', assert: true, echo: true]
  end

  it 'checks out FETCH_HEAD for a pull request' do
    payload[:job][:pull_request] = true
    should include_sexp [:cmd, 'git checkout -qf FETCH_HEAD', assert: true, echo: true]
  end

  describe 'submodules' do
    let(:sexp) { sexp_find(subject, [:if, '-f .gitmodules'], [:then]) }

    let(:no_host_key_check) { [:file, ['~/.ssh/config', "Host github.com\n\tStrictHostKeyChecking no\n"], append: true] }
    let(:submodule_init)    { [:cmd, 'git submodule init', assert: true, echo: true, timing: true] }
    let(:submodule_update)  { [:cmd, 'git submodule update', assert: true, echo: true, retry: true, timing: true] }

    describe 'if .gitmodules exists' do
      it { should include_sexp no_host_key_check }

      describe 'if :submodules_depth is not given' do
        it { should include_sexp submodule_init }
        it { should include_sexp submodule_update }
      end

      describe 'if :submodules_depth is given' do
        before { payload[:config][:git] = { submodules_depth: 50 } }
        it { should include_sexp submodule_init }
        it { should include_sexp [:cmd, 'git submodule update --depth=50', assert: true, echo: true, retry: true, timing: true] }
      end
    end

    describe 'submodules is set to false' do
      before { payload[:config][:git] = { submodules: false } }

      it { expect(sexp_find(subject, submodule_init)).to be_empty }
      it { expect(sexp_find(subject, submodule_update)).to be_empty }
    end
  end
end
