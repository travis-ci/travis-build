require 'spec_helper'

describe Repository::Github do
  let(:github) { Repository::Github.new(nil, 'travis-ci/travis-ci') }

  it 'config_url returns the github specific config url for the given commit' do
    github.config_url('1234567').should == 'http://raw.github.com/travis-ci/travis-ci/1234567/.travis.yml'
  end

  it 'source_url returns the github specific source url' do
    github.source_url.should == 'git://github.com/travis-ci/travis-ci.git'
  end

  it 'target_dir returns the slug' do
    github.target_dir.should == 'travis-ci/travis-ci'
  end
end
