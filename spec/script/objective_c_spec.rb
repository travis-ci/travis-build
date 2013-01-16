require 'spec_helper'

describe Travis::Build::Script::ObjectiveC do
  let(:options) { { logs: { build: false, state: false } } }
  let(:data)    { PAYLOADS[:push].deep_clone }

  before(:each) do
    data['config']['xcode_scheme'] = 'MyApp'
  end

  subject { described_class.new(data, options).compile }

  it 'announces xcodebuild -version -sdk' do
    should announce 'xcodebuild -version -sdk'
  end

  context 'if Podfile exists' do
    before(:each) do
      file('Podfile')
    end

    it 'runs pod install' do
      should install 'pod install'
      store_example 'objective_c_cocoapods'
    end
  end

  context 'if no Podfile exists' do
    it 'runs xcode tests' do
      should run_script 'xcodebuild  -scheme MyApp clean test'
    end
  end

  context 'when a workspace is given' do
    before(:each) do
      data['config']['xcode_workspace'] = 'MyWorkspace'
    end

    it 'runs xcode tests with workspace' do
      should run_script 'xcodebuild -workspace MyWorkspace.workspace -scheme MyApp clean test'
    end
  end
end
