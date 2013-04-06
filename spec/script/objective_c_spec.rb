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

  context 'if project is a RubyMotion project' do
    before(:each) do
      file('Podfile')
      file('Gemfile')
      file('Rakefile', "require 'motion/project'")
    end

    it 'runs bundle install' do
      should install 'bundle install'
      store_example 'rubymotion'
    end

    it 'runs pod install' do
      should install 'pod install'
    end

    it 'folds bundle install' do
      should fold 'bundle install', 'install.bundler'
    end

    it 'folds pod install' do
      should fold 'pod install', 'install.cocoapods'
    end

    it 'runs specs' do
      should run_script 'bundle exec rake spec'
    end
  end
end
