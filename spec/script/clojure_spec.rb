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
      is_expected.to announce 'lein version'
    end

    it 'installs lein deps' do
      is_expected.to travis_cmd 'lein deps', echo: true, timing: true, retry: true, assert: true
    end

    it 'runs lein test' do
      is_expected.to travis_cmd 'lein test', echo: true, timing: true
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
      is_expected.to announce 'lein2 version'
    end

    it 'installs lein2 deps if lein: lein2 given' do
      is_expected.to travis_cmd 'lein2 deps', echo: true, timing: true, retry: true, assert: true
    end

    it 'runs lein2 test if lein: lein2 given' do
      is_expected.to travis_cmd 'lein2 test', echo: true, timing: true
    end
  end

  describe '#cache_slug' do
    subject { described_class.new(data, options).cache_slug }
    it { is_expected.to eq('cache--jdk-default--lein-lein') }
  end
end
