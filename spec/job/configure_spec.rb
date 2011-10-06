require 'spec_helper'

describe Job::Configure do
  let(:response) { stub('response', :success? => true, :body => 'foo: Foo') }
  let(:http)     { stub('http', :get => response) }
  let(:commit)   { stub('commit', :config_url => 'http://raw.github.com/path/to/.travis.yml' ) }
  let(:job)      { Job::Configure.new(http, commit) }

  describe 'run' do
    it 'returns a hash' do
      job.run.should be_a(Hash)
    end

    it 'merges { .configured => true } to the actual configuration' do
      job.run['.configured'].should be_true
    end

    it 'yaml parses the response body if the response is successful' do
      job.run['foo'].should == 'Foo'
    end

    it 'returns a hash if the response is not successful' do
      response.expects(:success?).returns(false)
      job.run.should be_a(Hash)
    end

    it "GET's the commits's config_url" do
      commit.expects(:config_url)
      job.run
    end
  end
end
