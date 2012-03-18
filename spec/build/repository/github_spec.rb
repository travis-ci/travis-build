require 'spec_helper'
require 'travis/build'

describe Travis::Build::Repository::Github do
  let(:git)    { stub('git') }
  let(:github) { Travis::Build::Repository::Github.new(git, 'travis-ci/travis-ci') }

  it 'checkout fetches the given commit from the scm' do
    git.expects(:fetch).with('git://github.com/travis-ci/travis-ci.git', '1234567', 'travis-ci/travis-ci')
    github.checkout('1234567')
  end

  it 'source_url returns the github specific source url' do
    github.source_url.should == 'git://github.com/travis-ci/travis-ci.git'
  end
end
