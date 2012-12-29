require 'spec_helper'

describe Travis::Build::Script::Clojure do
  let(:data) { PAYLOADS[:push].deep_clone }

  subject { described_class.new(data).compile }

  it_behaves_like 'a build script'
  it_behaves_like 'a jdk build'

  describe 'if no lein config given' do
    it 'announces lein version' do
      should announce 'lein version'
    end

    it 'installs lein deps' do
      should install 'lein deps'
    end

    it 'runs lein test' do
      should run_script 'lein test'
    end
  end

  describe 'if lein: lein2 given' do
    before :each do
      data['config']['lein'] = 'lein2'
    end

    it 'announces lein2 version if lein: lein2 given' do
      should announce 'lein2 version'
    end

    it 'installs lein2 deps if lein: lein2 given' do
      should install 'lein2 deps'
    end

    it 'runs lein2 test if lein: lein2 given' do
      should run_script 'lein2 test'
    end
  end
end
