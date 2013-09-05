require 'spec_helper'

describe Travis::Build::Data do
  describe 'parse' do
    it 'extracts the source_host from an authenticated git url' do
      data = Travis::Build::Data.new(repository: { source_url: 'git@localhost:foo/bar.git' })
      data.source_host.should == 'localhost'
    end

    it 'extracts the source_host from an anonymous git url' do
      data = Travis::Build::Data.new(repository: { source_url: 'git://localhost/foo/bar.git' })
      data.source_host.should == 'localhost'
    end

    it 'extracts the source_host from an http url' do
      data = Travis::Build::Data.new(repository: { source_url: 'http://localhost/foo/bar.git' })
      data.source_host.should == 'localhost'
    end

    it 'extracts the source_host from an https url' do
      data = Travis::Build::Data.new(repository: { source_url: 'https://localhost/foo/bar.git' })
      data.source_host.should == 'localhost'
    end
  end
end
