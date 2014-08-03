require 'spec_helper'

describe Travis::Build::Script::DirectoryCache do
  let(:options) { { fetch_timeout: 20, push_timeout: 30, type: 's3', s3: { bucket: 's3_bucket', secret_access_key: 's3_secret_access_key', access_key_id: 's3_access_key_id' } } }
  let(:data)    { Travis::Build::Data.new(config: { cache: config }, cache_options: options) }
  let(:sh)      { Travis::Shell::Builder.new }
  let(:script)  { Struct.new(:sh, :data) { include(Travis::Build::Script::DirectoryCache) }.new(sh, data) }
  subject       { script }

  describe 'with no caching enabled' do
    let(:config) { {} }

    it { should_not be_use_directory_cache }

    describe '#cache_class' do
      subject { script.cache_class }
      it { should eq(Travis::Build::Script::DirectoryCache::Noop) }
    end
  end

  describe 'with caching enabled' do
    let(:config) { { directories: ['foo'] } }
    it { should be_use_directory_cache }

    describe '#cache_class' do
      subject { script.cache_class }
      it { should eq(Travis::Build::Script::DirectoryCache::S3) }
    end
  end
end
