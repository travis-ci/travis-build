require 'spec_helper'

describe Repository::Git do
  let(:implementation) do
    Class.new do
      include Repository::Git
      define_method(:source_url) { 'git://example.com/travis-ci/travis-ci.git' }
      define_method(:target_dir) { 'travis-ci/travis-ci' }
    end
  end

  let(:shell)   { stub('shell', :export => nil, :execute => true, :chdir => true) }
  let(:service) { implementation.new(shell) }

  describe 'fetch' do
    it 'makes sure interactive auth does not hang' do
      shell.expects(:export).with('GIT_ASKPASS', 'echo', :echo => false)
      service.fetch('1234567')
    end

    it 'clones the repository' do
      shell.expects(:execute).with('git clone --depth=100 --quiet git://example.com/travis-ci/travis-ci.git travis-ci/travis-ci')
      service.fetch('1234567')
    end

    it 'changes to the repository working directory' do
      shell.expects(:chdir).with('travis-ci/travis-ci')
      service.fetch('1234567')
    end

    it 'checks the given commit out' do
      shell.expects(:execute).with('git checkout -qf 1234567')
      service.fetch('1234567')
    end
  end
end
