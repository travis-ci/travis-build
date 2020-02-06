require 'spec_helper'

describe Travis::Build::Git::Clone, :sexp do
  let(:payload)  { payload_for(:push, :ruby) }
  let(:script)   { Travis::Build::Script.new(payload) }
  subject(:sexp) { script.sexp }

  let(:url)    { "https://github.com/#{payload[:repository][:slug]}.git" }
  let(:dir)    { payload[:repository][:slug] }
  let(:depth)  { Travis::Build::Git::DEFAULTS[:git][:depth] }
  let(:branch) { payload[:job][:branch] || 'master' }

  let(:oauth_token) { 'abcdef01234' }
  let(:netrc)  { /echo -e "machine #{host}\\n  login #{oauth_token}\\n" > \${TRAVIS_HOME}\/\.netrc/ }
  let(:host)   { 'github.com' }

  before :each do
    payload[:config][:git] = { strategy: 'clone' }
  end

  describe 'when the repository is not yet cloned' do
    let(:args) { "--depth=#{depth} --branch=#{branch.shellescape}" }
    let(:cmd)  { "git clone #{args} #{url} #{dir}" }
    subject    { sexp_find(sexp, [:if, "! -d #{dir}/.git"]) }

    let(:clone) { [:cmd, cmd, echo: true, retry: true, timing: true] }

    describe 'with no depth specified' do
      it { should include_sexp clone }
    end

    describe 'with a custom depth' do
      let(:depth) { 1 }
      before { payload[:config][:git]['depth'] = depth }
      it { should include_sexp clone }
    end

    describe 'with depth "false"' do
      let(:depth) { false }
      let(:args) { " --branch=#{branch.shellescape}" }
      before { payload[:config][:git]['depth'] = depth }
      it { should include_sexp clone }
    end

    describe 'with lfs_skip_smudge true' do
      before { payload[:config][:git]['lfs_skip_smudge'] = true }
      it { expect(sexp).to include_sexp [:export, ['GIT_LFS_SKIP_SMUDGE', '1'], echo: true] }
    end

    describe 'escapes the branch name' do
      before { payload[:job][:branch] = 'foo->bar' }
      it { should include_sexp clone }
    end

    context 'when git.quiet is true' do
      before :each do
        payload[:config][:git].merge!({ quiet: true })
      end
      let(:args) { "--depth=#{depth} --branch=#{branch.shellescape} --quiet" }
      it { should include_sexp clone }
    end
  end

  describe 'when the repository is already cloned' do
    subject         { sexp_find(sexp, [:if, "! -d #{dir}/.git"], [:else]) }

    let(:fetch)     { [:cmd, "git -C #{payload[:repository][:slug]} fetch origin", assert: true, echo: true, retry: true, timing: true] }
    let(:reset)     { [:cmd, "git -C #{payload[:repository][:slug]} reset --hard", assert: true, echo: true] }

    it { should include_sexp fetch }
    it { should include_sexp reset }

    context 'when git.quiet is true' do
      before :each do
        payload[:config][:git].merge!({ quiet: true })
      end

      let(:quiet_fetch)     { [:cmd, "git -C #{payload[:repository][:slug]} fetch origin --quiet", assert: true, echo: true, retry: true, timing: true] }

      it { should include_sexp quiet_fetch }
    end
  end

  let(:cd)            { [:cd,  payload[:repository][:slug], echo: true] }
  let(:fetch_ref)     { [:cmd, %r(git fetch origin \+[\w/]+:), assert: true, echo: true, retry: true, timing: true] }
  let(:checkout_push) { [:cmd, "git checkout -qf #{payload[:job][:commit]}", assert: true, echo: true] }
  let(:checkout_tag)  { [:cmd, 'git checkout -qf v1.0.0', assert: true, echo: true] }
  let(:checkout_pull) { [:cmd, 'git checkout -qf FETCH_HEAD', assert: true, echo: true] }
  let(:checkout_pull_fetch_head_alternative) { [:cmd, "git merge --squash #{payload[:job][:branch]}", assert: true, echo: true] }

  it { should include_sexp cd }

  describe 'with a ref given' do
    before { payload[:job][:ref] = 'refs/pull/118/merge' }
    it { should include_sexp fetch_ref }

    context 'when git.quiet is true' do
      before :each do
        payload[:config][:git].merge!({ quiet: true })
      end

      let(:quiet_fetch_ref) { [:cmd, %r(git fetch origin \+[\w/]+: --quiet), assert: true, echo: true, retry: true, timing: true] }

      it { should include_sexp quiet_fetch_ref }
    end
  end

  describe 'with a tag given' do
    before { payload[:job][:tag] = 'v1.0.0' }
    it { should include_sexp checkout_tag }
  end

  describe 'with no ref or tag given' do
    it { should_not include_sexp fetch_ref }
    it { should_not include_sexp checkout_tag }
  end

  describe 'checks out the given commit for a push request' do
    before { payload[:job][:pull_request] = false }
    it { should include_sexp checkout_push }
  end

  describe 'checks out the given commit for a pull request' do
    before { payload[:job][:pull_request] = true }
    it { should include_sexp checkout_pull }
  end

  describe 'checks out the given commit for a pull request' do
    before { payload[:job][:pull_request] = true }
    before { payload[:job][:pull_request_head_branch] = "#{payload[:job][:branch]}_new" }
    before { payload[:repository][:vcs_type] = 'BitbucketRepository' }
    it { should include_sexp checkout_pull_fetch_head_alternative }
  end

  context "When sparse_checkout is requested" do
    before { payload[:config][:git]['sparse_checkout'] = 'sparse_checkout_file' }
    it { should include_sexp [:cmd, "git -C #{payload[:repository][:slug]} pull origin master --depth=50", echo: true, timing: true, retry: true]}
    it { should include_sexp [:cmd, "echo sparse_checkout_file >> #{payload[:repository][:slug]}/.git/info/sparse-checkout", assert: true, echo: true, timing: true, retry: true]}
    it { should include_sexp [:cmd, "cat #{payload[:repository][:slug]}/sparse_checkout_file >> #{payload[:repository][:slug]}/.git/info/sparse-checkout", assert: true, echo: true, timing: true, retry: true]}
    it { store_example(name: 'git sparse checkout') }
  end

  describe 'autocrlf option' do
    context 'when autocrlf is not given' do
      it "preserves the default" do
        should_not include_sexp [:cmd, /git config --global core\.autocrlf/]
      end
    end

    context 'when autocrlf is set to "true"' do
      before { payload[:config][:git]['autocrlf'] = 'true' }

      it { should include_sexp [:cmd, "git config --global core.autocrlf true", assert: true, echo: true, timing: true] }
      it { store_example(name: 'git autocrlf true') }
    end

    context 'when autocrlf is set to "false"' do
      before { payload[:config][:git]['autocrlf'] = false }

      it { should include_sexp [:cmd, "git config --global core.autocrlf false", assert: true, echo: true, timing: true] }
      it { store_example(name: 'git autocrlf false') }
    end

    context 'when autocrlf is set to "input"' do
      before { payload[:config][:git]['autocrlf'] = 'input' }

      it { should include_sexp [:cmd, "git config --global core.autocrlf input", assert: true, echo: true, timing: true] }
      it { store_example(name: 'git autocrlf input') }
    end

    context 'when autocrlf is set to "invlaid"' do
      before { payload[:config][:git]['autocrlf'] = 'invlaid' }

      it { should include_sexp [:cmd, "git config --global core.autocrlf invlaid", assert: true, echo: true, timing: true] }
      it { store_example(name: 'git autocrlf invlaid') }
    end
  end
end
