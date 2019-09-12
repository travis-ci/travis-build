require 'spec_helper'

describe Travis::Build::Git::Clone, :sexp do
  let(:payload)  { payload_for(:push, :ruby) }
  let(:script)   { Travis::Build::Script.new(payload) }
  subject(:sexp) { script.sexp }

  let(:url)    { "git://github.com/#{payload[:repository][:slug]}.git" }
  let(:dir)    { payload[:repository][:slug] }
  let(:depth)  { Travis::Build::Git::DEFAULTS[:git][:depth] }
  let(:branch) { payload[:job][:branch] || 'master' }

  let(:oauth_token) { 'abcdef01234' }
  let(:netrc)  { /echo -e "machine #{host}\\n  login #{oauth_token}\\n" > \$HOME\/\.netrc/ }
  let(:host)   { 'github.com' }

  before :each do
    payload[:config][:git] = { strategy: 'clone' }
  end

  context 'when source_url starts with "https"' do
    before { payload[:repository][:source_url] = "https://github.com/#{payload[:repository][:slug]}.git" }

    context "when payload includes oauth_token" do
      # case where (in Enterprise) scheduler sets the source URL with https
      before { payload[:oauth_token] = oauth_token }

      it 'writes to $HOME/.netrc' do
        expect(script.sexp).to include_sexp [:raw, netrc, assert: true ]
      end
    end

    context "when payload does not include oauth_token" do
      # hosted .org
      it 'does not write to $HOME/.netrc' do
        should_not include_sexp [:raw, netrc, assert: true ]
      end
    end
  end

  context 'when source_url starts with "https" on a GitHub Enterprise host' do
    let(:host) { 'ghe.example.com'}
    before { payload[:repository][:source_url] = "https://#{host}/#{payload[:repository][:slug]}.git" }

    context "when payload includes oauth_token" do
      # case where (in Enterprise) scheduler sets the source URL with https
      before { payload[:oauth_token] = oauth_token }

      it 'writes to $HOME/.netrc' do
        expect(script.sexp).to include_sexp [:raw, netrc, assert: true ]
      end
    end

    context "when payload does not include oauth_token" do
      # hosted .org
      it 'does not write to $HOME/.netrc' do
        should_not include_sexp [:raw, netrc, assert: true ]
      end
    end
  end

  context 'with an https source_url and an installation_id' do
    let(:netrc)  { /echo -e "machine #{host}\\n  login travis-ci\\n  password access_token\\n" > \$HOME\/\.netrc/ }

    before { Travis::GithubApps.any_instance.stubs(:access_token).returns 'access_token' }
    before { payload[:repository][:source_url] = "https://github.com/#{payload[:repository][:slug]}.git" }
    before { payload[:repository][:installation_id] = 1 }

    context 'given no custom ssh key' do
      it 'writes to $HOME/.netrc' do
        expect(script.sexp).to include_sexp [:raw, netrc, assert: true ]
      end
    end

    context 'given a repository settings key' do
      before { payload[:ssh_key] = { source: 'repository_settings', value: 'key', encoded: false } }

      it 'does not write to $HOME/.netrc' do
        should_not include_sexp [:raw, netrc, assert: true ]
      end
    end

    context 'given a travis yaml key' do
      before { payload[:ssh_key] = { source: 'travis_yaml', value: 'key', encoded: false } }

      it 'does not write to $HOME/.netrc' do
        should_not include_sexp [:raw, netrc, assert: true ]
      end
    end

    context 'given a default repository key' do
      before { payload[:ssh_key] = { source: 'default_repository_key', value: 'key', encoded: false } }

      it 'writes to $HOME/.netrc' do
        expect(script.sexp).to include_sexp [:raw, netrc, assert: true ]
      end
    end
  end

  context 'when source_url starts with "git"' do
    context "when payload includes oauth_token" do
      # hosted .com, or Enterprise with default config
      before { payload[:oauth_token] = oauth_token }

      it 'does not write to $HOME/.netrc' do
        should_not include_sexp [:raw, netrc, assert: true ]
      end
    end

    context "when payload does not include oauth_token" do
      # this should not happen
      it 'does not write to $HOME/.netrc' do
        should_not include_sexp [:raw, netrc, assert: true ]
      end
    end
  end

  context 'when source_url starts with "git"' do
    it 'deos not write to $HOME/.netrc' do
      should_not include_sexp [:raw, netrc, assert: true ]
    end
  end


  describe 'when the repository is not yet cloned' do
    let(:args) { "--depth=#{depth} --branch=#{branch.shellescape}" }
    let(:cmd)  { "git clone #{args} #{url} #{dir}" }
    subject    { sexp_find(sexp, [:if, "! -d #{dir}/.git"]) }

    let(:clone) { [:cmd, cmd, echo: true, retry: true, timing: true] }

    describe 'with no depth specified' do
      before { payload[:repository][:source_url] =  "git://github.com/#{payload[:repository][:slug]}.git" }
      it { should include_sexp clone }
    end

    describe 'with a custom depth' do
      let(:depth) { 1 }
      before { payload[:config][:git]['depth'] = depth }
      before { payload[:repository][:source_url] =  "git://github.com/#{payload[:repository][:slug]}.git" }
      it { should include_sexp clone }
    end

    describe 'with depth "false"' do
      let(:depth) { false }
      let(:args) { " --branch=#{branch.shellescape}" }
      before { payload[:config][:git]['depth'] = depth }
      before { payload[:repository][:source_url] =  "git://github.com/#{payload[:repository][:slug]}.git" }
      it { should include_sexp clone }
    end

    describe 'with lfs_skip_smudge true' do
      before { payload[:config][:git]['lfs_skip_smudge'] = true }
      it { expect(sexp).to include_sexp [:export, ['GIT_LFS_SKIP_SMUDGE', '1'], echo: true] }
    end

    describe 'escapes the branch name' do
      before { payload[:job][:branch] = 'foo->bar' }
      before { payload[:repository][:source_url] =  "git://github.com/#{payload[:repository][:slug]}.git" }
      it { should include_sexp clone }
    end

    context 'when git.quiet is true' do
      before :each do
        payload[:config][:git].merge!({ quiet: true })
      end
      let(:args) { "--depth=#{depth} --branch=#{branch.shellescape} --quiet" }
      before { payload[:repository][:source_url] =  "git://github.com/#{payload[:repository][:slug]}.git" }
      it { should include_sexp clone }
    end
  end

  describe 'when the repository is already cloned' do
    subject         { sexp_find(sexp, [:if, "! -d #{dir}/.git"], [:else]) }

    let(:fetch)     { [:cmd, "git -C #{payload[:repository][:slug]} fetch origin", assert: true, echo: true, retry: true, timing: true] }
    let(:reset)     { [:cmd, "git -C #{payload[:repository][:slug]} reset --hard", assert: true, echo: true] }

    it { should include_sexp fetch }
    it { should include_sexp reset }
  end

  let(:cd)            { [:cd,  payload[:repository][:slug], echo: true] }
  let(:fetch_ref)     { [:cmd, %r(git fetch origin \+[\w/]+:), assert: true, echo: true, retry: true, timing: true] }
  let(:checkout_push) { [:cmd, "git checkout -qf #{payload[:job][:commit]}", assert: true, echo: true] }
  let(:checkout_tag)  { [:cmd, 'git checkout -qf v1.0.0', assert: true, echo: true] }
  let(:checkout_pull) { [:cmd, 'git checkout -qf FETCH_HEAD', assert: true, echo: true] }

  it { should include_sexp cd }

  describe 'with a ref given' do
    before { payload[:job][:ref] = 'refs/pull/118/merge' }
    it { should include_sexp fetch_ref }
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

  context "When sparse_checkout is requested" do
    before { payload[:config][:git]['sparse_checkout'] = 'sparse_checkout_file' }
    it { should include_sexp [:cmd, "git -C #{payload[:repository][:slug]} pull origin master --depth=50", echo: true, timing: true, retry: true]}
    it { should include_sexp [:cmd, "echo sparse_checkout_file >> #{payload[:repository][:slug]}/.git/info/sparse-checkout", assert: true, echo: true, timing: true, retry: true]}
    it { should include_sexp [:cmd, "cat #{payload[:repository][:slug]}/sparse_checkout_file >> #{payload[:repository][:slug]}/.git/info/sparse-checkout", assert: true, echo: true, timing: true, retry: true]}
    it { store_example(name: 'git sparse checkout')}
  end
end
