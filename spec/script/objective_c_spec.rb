require 'spec_helper'

describe Travis::Build::Script::ObjectiveC do
  let(:options) { { logs: { build: false, state: false } } }
  let(:data)    { PAYLOADS[:push].deep_clone }

  subject { described_class.new(data, options).compile }

  it 'announces xcodebuild -version -sdk' do
    is_expected.to announce 'xcodebuild -version -sdk'
  end

  it 'folds announce' do
    is_expected.to fold 'xcodebuild -version -sdk', 'announce'
  end

  it 'handles ruby version being set' do
    data['config']['rvm'] = 'system'
    is_expected.to travis_cmd 'rvm use system --install --binary --fuzzy', echo: true, timing: true, assert: true
  end

  it 'sets TRAVIS_XCODE_SDK' do
    data['config']['xcode_sdk'] = 'iphonesimulator7.0'
    is_expected.to set 'TRAVIS_XCODE_SDK', 'iphonesimulator7.0'
  end

  it 'sets TRAVIS_XCODE_SCHEME' do
    data['config']['xcode_scheme'] = 'MyTests'
    is_expected.to set 'TRAVIS_XCODE_SCHEME', 'MyTests'
  end

  it 'sets TRAVIS_XCODE_PROJECT' do
    data['config']['xcode_project'] = 'MyProject.xcodeproj'
    is_expected.to set 'TRAVIS_XCODE_PROJECT', 'MyProject.xcodeproj'
  end

  it 'sets TRAVIS_XCODE_WORKSPACE' do
    data['config']['xcode_workspace'] = 'MyWorkspace.xcworkspace'
    is_expected.to set 'TRAVIS_XCODE_WORKSPACE', 'MyWorkspace.xcworkspace'
  end

  context 'if Podfile exists' do
    before(:each) do
      file('Podfile')
    end

    it 'announces CocoaPods version' do
      is_expected.to announce 'pod --version'
    end

    it 'runs pod install' do
      is_expected.to travis_cmd 'pod install', echo: true, timing: true, assert: true, retry: true
      store_example 'cocoapods'
    end

    it 'folds pod install' do
      is_expected.to fold 'pod install', 'install.cocoapods'
    end

    context "if Podfile.lock and Pods/Manifest.lock is the same" do
      before do
        file("Podfile.lock", "abcd")
        file("Pods/Manifest.lock", "abcd")
      end

      it "does not run pod install" do
        is_expected.not_to install "pod install"
      end
    end
  end

  context "custom Podfile exists" do
    before do
      file('foo/Podfile')
      data['config']['podfile'] = 'foo/Podfile'
    end

    it 'runs Pod install in Podfile directory' do
      is_expected.to run 'pushd foo'
    end

    context 'if Podfile.lock and Pods/Manifest.lock is the same' do
      before do
        file("foo/Podfile.lock", "abcd")
        file("foo/Pods/Manifest.lock", "abcd")
      end

      it "does not run pod install" do
        is_expected.not_to install "pod install"
      end
    end
  end

  context 'if no settings are specified' do
    it 'prints a warning' do
      is_expected.to run /WARNING/
    end
  end

  context 'if workspace and scheme is given' do
    before(:each) do
      data['config']['xcode_workspace'] = 'YourWorkspace.xcworkspace'
      data['config']['xcode_scheme'] = 'YourScheme'
    end

    it 'runs xctool' do
      is_expected.to travis_cmd 'xctool -workspace YourWorkspace.xcworkspace -scheme YourScheme build test', echo: true, timing: true
      store_example 'xctool'
    end
  end

  context 'if project and scheme is given' do
    before(:each) do
      data['config']['xcode_project'] = 'YourProject.xcodeproj'
      data['config']['xcode_scheme'] = 'YourScheme'
    end

    it 'runs xctool' do
      is_expected.to travis_cmd 'xctool -project YourProject.xcodeproj -scheme YourScheme build test', echo: true, timing: true
    end

    context 'if an SDK version is passed' do
      before do
        data['config']['xcode_sdk'] = '7.0'
      end

      it 'passes it to xctool' do
        is_expected.to travis_cmd 'xctool -project YourProject.xcodeproj -scheme YourScheme -sdk 7.0 build test', echo: true, timing: true
      end
    end
  end

  context 'if project is a RubyMotion project' do
    before(:each) do
      file('Rakefile', "require 'motion/project/template/ios'")
    end

    it 'announces RubyMotion version' do
      is_expected.to announce 'motion --version'
    end

    it 'runs specs' do
      is_expected.to travis_cmd 'rake spec', echo: true, timing: true
      store_example 'rubymotion'
    end

    context 'with a Gemfile' do
      before(:each) do
        file('Gemfile')
      end

      it 'runs bundle install' do
        is_expected.to travis_cmd 'bundle install', echo: true, timing: true, assert: true, retry: true
      end

      it 'folds bundle install' do
        is_expected.to fold 'bundle install', 'install.bundler'
      end

      it 'runs specs with Bundler' do
        is_expected.to travis_cmd 'bundle exec rake spec', echo: true, timing: true
      end
    end
  end

  describe '#cache_slug' do
    subject { described_class.new(data, options) }

    describe '#cache_slug' do
      subject { super().cache_slug }
      it { is_expected.to eq('cache--rvm-default--gemfile-Gemfile') }
    end

    describe 'with custom gemfile' do
      before do
        gemfile 'foo'
      end

      describe '#cache_slug' do
        subject { super().cache_slug }
        it { is_expected.to eq('cache--rvm-default--gemfile-foo') }
      end
    end

    describe 'with custom ruby version' do
      before { data['config']['rvm'] = 'jruby' }

      describe '#cache_slug' do
        subject { super().cache_slug }
        it { is_expected.to eq('cache--rvm-jruby--gemfile-Gemfile') }
      end
    end
  end
end
