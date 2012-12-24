require 'spec_helper'

describe Travis::Build::Script::Clojure do
  let(:config) { PAYLOADS[:push].deep_clone }

  subject { described_class.new(config).compile }

  it_behaves_like 'a build script'
  it_behaves_like 'a jdk build'

  describe 'if no lein config given' do
    it 'announces lein version' do
      should run 'lein version', echo: true, log: true
    end

    it 'installs lein deps' do
      should run 'lein deps', echo: true, log: true, assert: true, timeout: timeout_for(:install)
    end

    it 'runs lein test' do
      should run 'lein test', echo: true, log: true, timeout: timeout_for(:script)
    end
  end

  describe 'if lein: lein2 given' do
    before :each do
      config['config']['lein'] = 'lein2'
    end

    it 'announces lein2 version if lein: lein2 given' do
      should run 'lein2 version', echo: true, log: true
    end

    it 'installs lein2 deps if lein: lein2 given' do
      should run 'lein2 deps', echo: true, log: true, assert: true, timeout: timeout_for(:install)
    end

    it 'runs lein2 test if lein: lein2 given' do
      should run 'lein2 test', echo: true, log: true, timeout: timeout_for(:script)
    end
  end
end
