require 'spec_helper'
require 'travis/build'

describe Travis::Build::Scm::Git do
  let(:shell)  { stub('shell', :export => nil, :execute => true, :chdir => true, :file_exists? => false) }
  let(:scm)    { Travis::Build::Scm::Git.new(shell) }

  let(:source) { 'git://example.com/travis-ci.git' }
  let(:target) { 'travis-ci' }
  let(:sha)    { '1234567' }
  let(:branch) { 'master' }
  let(:ref)    { nil }

  describe 'fetch' do
    it 'makes sure interactive auth does not hang' do
      shell.expects(:export).with('GIT_ASKPASS', 'echo', :echo => false)
      scm.fetch(source, target, sha, branch, ref)
    end

    it 'clones the repository' do
      shell.expects(:execute).with('git clone --branch=master --depth=100 --quiet git://example.com/travis-ci.git travis-ci').returns(true)
      scm.fetch(source, target, sha, branch, ref)
    end

    it 'clones the repository' do
      shell.expects(:execute).with('git clone --branch=dev --depth=100 --quiet git://example.com/travis-ci.git travis-ci').returns(true)
      scm.fetch(source, target, sha, 'dev', ref)
    end

    it 'changes to the repository working directory' do
      shell.expects(:chdir).with('travis-ci')
      scm.fetch(source, target, sha, branch, ref)
    end

    it 'checks the given commit out' do
      shell.expects(:execute).with('git checkout -qf 1234567').returns(true)
      scm.fetch(source, target, sha, branch, ref)
    end

    it 'fetches the ref before checking out the given commit out' do
      ref = 'refs/pulls/180/merge'
      shell.expects(:execute).with("git fetch origin +refs/pulls/180/merge:").returns(true)
      shell.expects(:execute).with('git checkout -qf FETCH_HEAD').returns(true)
      scm.fetch(source, target, sha, branch, ref)
    end

    it 'sets up submodules if .gitmodules exists' do
      shell.expects(:file_exists?).with('.gitmodules').returns(true)
      shell.expects(:execute).with('git submodule init').returns(true)
      shell.expects(:execute).with('git submodule update').returns(true)
      scm.fetch(source, target, sha, branch, ref)
    end
  end
end
