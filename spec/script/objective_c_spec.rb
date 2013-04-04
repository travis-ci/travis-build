require 'spec_helper'

describe Travis::Build::Script::ObjectiveC do
  let(:options) { { logs: { build: false, state: false } } }
  let(:data)    { PAYLOADS[:push].deep_clone }

  subject { described_class.new(data, options).compile }

  it 'announces xcodebuild -version -sdk' do
    should announce 'xcodebuild -version -sdk'
  end

  it 'folds announce' do
    should fold 'xcodebuild -version -sdk', 'announce'
  end

  context 'if Podfile exists' do
    before(:each) do
      file('Podfile')
    end

    it 'runs pod install' do
      should install 'pod install'
      store_example 'cocoapods'
    end

    it 'folds pod install' do
      should fold 'pod install', 'install'
    end
  end

  context 'if no Podfile exists' do
    it 'runs xcode tests' do
      should run_script '/Users/travis/travis-utils/osx-cibuild.sh'
      store_example
    end
  end
end
