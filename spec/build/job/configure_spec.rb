require 'spec_helper'
require 'spec_helper/payloads'
require 'travis/build'

describe Travis::Build::Job::Configure do
  let(:response) { stub('response', :success? => true, :body => 'foo: Foo') }
  let(:http)     { stub('http', :get => response) }
  let(:payload)  { Hashr.new(PAYLOADS[:configure]) }
  let(:commit)   { Travis::Build::Commit.new(payload.build, payload.repository, stub('scm')) }
  let(:job)      { Travis::Build::Job::Configure.new(http, commit) }

  describe 'run' do
    it 'returns a hash' do
      job.run.should be_a(Hash)
    end

    it 'merges { .configured => true } to the actual configuration' do
      job.run['config']['.configured'].should be_true
    end

    it 'yaml parses the response body if the response is successful' do
      job.run['config']['foo'].should == 'Foo'
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
