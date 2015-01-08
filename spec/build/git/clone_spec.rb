require 'spec_helper'

describe Travis::Build::Git::Clone, :sexp do
  let(:payload)  { payload_for(:push, :ruby) }
  let(:script)   { Travis::Build::Script.new(payload) }
  subject(:sexp) { sexp_find(script.sexp, [:fold, 'git.checkout']) }

  let(:url)    { 'git://github.com/travis-ci/travis-ci.git' }
  let(:dir)    { 'travis-ci/travis-ci' }
  let(:depth)  { Travis::Build::Git::DEFAULTS[:git][:depth] }
  let(:branch) { payload[:job][:branch] || 'master' }

  before :each do
    payload[:config][:git] = { strategy: 'clone' }
  end

  describe 'when the repository is cloned not yet' do
    let(:args) { "--depth=#{depth} --branch=#{branch.shellescape}" }
    let(:cmd)  { "git clone #{args} #{url} #{dir}" }
    subject    { sexp_find(sexp, [:if, "! -d #{dir}/.git"]) }

    let(:clone) { [:cmd, cmd, assert: true, echo: true, retry: true, timing: true] }

    describe 'with no depth specified' do
      it { should include_sexp clone }
    end

    describe 'with a custom depth' do
      let(:depth) { 1 }
      before { payload[:config][:git]['depth'] = depth }
      it { should include_sexp clone }
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

    let(:fetch)     { [:cmd, 'git -C travis-ci/travis-ci fetch origin', assert: true, echo: true, retry: true, timing: true] }
    let(:reset)     { [:cmd, 'git -C travis-ci/travis-ci reset --hard', assert: true, echo: true] }

    it { should include_sexp fetch }
    it { should include_sexp reset }
  end

  let(:cd)            { [:cd,  'travis-ci/travis-ci', echo: true] }
  let(:fetch_ref)     { [:cmd, %r(git fetch origin \+[\w/]+:), assert: true, echo: true, retry: true, timing: true] }
  let(:checkout_push) { [:cmd, 'git checkout -qf 313f61b', assert: true, echo: true] }
  let(:checkout_pull) { [:cmd, 'git checkout -qf FETCH_HEAD', assert: true, echo: true] }

  it { should include_sexp cd }

  describe 'with a ref given' do
    before { payload[:job][:ref] = 'refs/pull/118/merge' }
    it { should include_sexp fetch_ref }
  end

  describe 'with no ref given' do
    it { should_not include_sexp fetch_ref }
  end

  describe 'checks out the given commit for a push request' do
    before { payload[:job][:pull_request] = false }
    it { should include_sexp checkout_push }
  end

  describe 'checks out the given commit for a pull request' do
    before { payload[:job][:pull_request] = true }
    it { should include_sexp checkout_pull }
  end
end
