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

  it 'handles ruby version being set' do
    data['config']['rvm'] = 'system'
    should setup 'rvm use system'
  end

  context 'if Podfile exists' do
    before(:each) do
      file('Podfile')
    end

    it 'announces CocoaPods version' do
      should announce 'pod --version'
    end

    it 'runs pod install' do
      should install 'pod install', retry: true
      store_example 'cocoapods'
    end

    it 'folds pod install' do
      should fold 'pod install', 'install'
    end
  end

  context 'if no settings are specified' do
    it 'runs xcode tests' do
      should run_script '/Users/travis/travis-utils/osx-cibuild.sh'
      store_example
    end
  end

  context 'if workspace and scheme is given' do
    before(:each) do
      data['config']['xcode_workspace'] = 'YourWorkspace.xcworkspace'
      data['config']['xcode_scheme'] = 'YourScheme'
    end

    it 'runs xctool' do
      should run_script 'xctool -workspace YourWorkspace.xcworkspace -scheme YourScheme build test'
      store_example 'xctool'
    end
  end

  context 'if project and scheme is given' do
    before(:each) do
      data['config']['xcode_project'] = 'YourProject.xcodeproj'
      data['config']['xcode_scheme'] = 'YourScheme'
    end

    it 'runs xctool' do
      should run_script 'xctool -project YourProject.xcodeproj -scheme YourScheme build test'
    end
  end

  context 'if project is a RubyMotion project' do
    before(:each) do
      file('Rakefile', "require 'motion/project/template/ios'")
    end

    it 'announces RubyMotion version' do
      should announce 'motion --version'
    end

    it 'runs specs' do
      should run_script 'rake spec'
      store_example 'rubymotion'
    end

    context 'with a Gemfile' do
      before(:each) do
        file('Gemfile')
      end

      it 'runs bundle install' do
        should install 'bundle install', retry: true
      end

      it 'folds bundle install' do
        should fold 'bundle install', 'install.bundler'
      end

      it 'runs specs with Bundler' do
        should run_script 'bundle exec rake spec'
      end
    end
  end
end
