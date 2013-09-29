require 'spec_helper'

describe Travis::Build::Script::Clojure do
  let(:options) { { logs: { build: false, state: false } } }
  let(:data)    { PAYLOADS[:push].deep_clone }

  subject { described_class.new(data, options).compile }

  it_behaves_like 'a build script'
  it_behaves_like 'a jdk build'

  describe 'if no lein config given' do
    after :all do
      store_example 'no lein config'
    end

    it 'announces lein version' do
      should announce 'lein version'
    end

    it 'installs lein deps' do
      should install 'lein deps'
    end

    it 'retries len deps' do
      should retry_script 'lein deps'
    end

    it 'runs lein test' do
      should run_script 'lein test'
    end
  end

  describe 'if lein: lein2 given' do
    before :each do
      data['config']['lein'] = 'lein2'
    end

    after :all do
      store_example 'lein2 config'
    end

    it 'announces lein2 version if lein: lein2 given' do
      should announce 'lein2 version'
    end

    it 'installs lein2 deps if lein: lein2 given' do
      should install 'lein2 deps'
    end

    it 'retries lein2 deps if lein: lein2 given' do
      should retry_script 'lein2 deps'
    end

    it 'runs lein2 test if lein: lein2 given' do
      should run_script 'lein2 test'
    end
  end

  describe :cache_slug do
    subject { described_class.new(data, options) }
    its(:cache_slug) { should be == 'cache--jdk-default--lein-lein' }
  end
end
