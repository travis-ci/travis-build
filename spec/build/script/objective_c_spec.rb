require 'spec_helper'

describe Travis::Build::Script::ObjectiveC, :sexp do
  let(:data)   { payload_for(:push, :objective_c) }
  let(:script) { described_class.new(data) }
  let(:is_ruby_motion) { "-f Rakefile && \"$(cat Rakefile)\" =~ require\\ [\\\"\\']motion/project" }
  subject      { script.sexp }
  it           { store_example }

  it_behaves_like 'a bash script'

  it_behaves_like 'compiled script' do
    let(:code) { ['TRAVIS_LANGUAGE=objective_c'] }
    let(:cmds) { ['bundle exec rake spec'] }
  end

  it_behaves_like 'a build script sexp'

  describe 'announce' do
    let(:fold) { sexp_find(subject, [:fold, 'announce']) }

    it 'announces xcodebuild -version -sdk' do
      expect(fold).to include_sexp [:cmd, 'xcodebuild -version -sdk', echo: true]
    end

    it 'announces RubyMotion version if project is a RubyMotion project' do
      sexp = sexp_find(subject, [:if, is_ruby_motion], [:then])
      expect(sexp).to include_sexp [:cmd, 'motion --version', echo: true]
    end

    it 'announces CocoaPods version if a Podfile exists' do
      sexp = sexp_filter(subject, [:if, '-f Podfile'])[1]
      expect(sexp).to include_sexp [:cmd, 'pod --version', echo: true]
    end
  end

  describe 'setup' do
    it 'handles ruby version being set' do
      data[:config][:rvm] = 'system'
      should include_sexp [:cmd, 'rvm use system --install --binary --fuzzy', echo: true, timing: true, assert: true]
    end
  end

  describe 'export' do
    it 'sets TRAVIS_XCODE_SDK' do
      data[:config][:xcode_sdk] = 'iphonesimulator7.0'
      should include_sexp [:export, ['TRAVIS_XCODE_SDK', 'iphonesimulator7.0']]
    end

    it 'sets TRAVIS_XCODE_SCHEME' do
      data[:config][:xcode_scheme] = 'MyTests'
      should include_sexp [:export, ['TRAVIS_XCODE_SCHEME', 'MyTests']]
    end

    it 'sets TRAVIS_XCODE_PROJECT' do
      data[:config][:xcode_project] = 'MyProject.xcodeproj'
      should include_sexp [:export, ['TRAVIS_XCODE_PROJECT', 'MyProject.xcodeproj']]
    end

    it 'sets TRAVIS_XCODE_WORKSPACE' do
      data[:config][:xcode_workspace] = 'MyWorkspace.xcworkspace'
      should include_sexp [:export, ['TRAVIS_XCODE_WORKSPACE', 'MyWorkspace.xcworkspace']]
    end

    it 'sets TRAVIS_XCODE_DESTINATION' do
      data[:config][:xcode_destination] = 'platform=iOS Simulator,name=iPhone X'
      should include_sexp [:export, ['TRAVIS_XCODE_DESTINATION', 'platform\=iOS\ Simulator,name\=iPhone\ X']]
    end
  end

  describe 'install' do
    it 'runs bundle install if the project is a RubyMotion project' do
      sexp = sexp_find(sexp_filter(subject, [:if, "-f ${BUNDLE_GEMFILE:-Gemfile}"])[1], [:then])
      expect(sexp).to include_sexp [:cmd, 'bundle install --jobs=3 --retry=3', echo: true, timing: true, assert: true, retry: true]
    end

    it 'runs bundle exec pod install if a Podfile and Gemfile exists' do
      sexp = sexp_find(sexp_filter(subject, [:if, "-f ${BUNDLE_GEMFILE:-Gemfile}"])[2], [:then])
      expect(sexp).to include_sexp [:cmd, 'bundle exec pod install', assert: true, echo: true, retry: true, timing: true]
    end

    it 'runs pod install if a Podfile exists' do
      sexp = sexp_filter(subject, [:if, '-f Podfile'])[2]
      expect(sexp).to include_sexp [:cmd, 'pod install', assert: true, echo: true, retry: true, timing: true]
    end

    it 'does not run pod install if Podfile.lock and Pods/Manifest.lock is the same' do
      sexp = sexp_find(subject, [:if, %r(-f ./Podfile.lock && -f ./Pods/Manifest.lock.* && cmp --silent)])
      expect(sexp).to include_sexp [:cmd, 'pod install', assert: true, echo: true, retry: true, timing: true]
    end
  end

  describe 'script' do
    let(:sexp) { sexp_find(subject, [:if, "#{is_ruby_motion} && -f Gemfile"]) }

    describe 'if the project is a RubyMotion project' do
      it 'runs `rake spec`' do
        branch = sexp_find(sexp, [:then])
        expect(branch).to include_sexp [:cmd, 'bundle exec rake spec', echo: true, timing: true]
      end

      it 'runs `bundle exec rake spec` if there is a Gemfile' do
        branch = sexp_find(sexp, [:elif, is_ruby_motion])
        expect(branch).to include_sexp [:cmd, 'rake spec', echo: true, timing: true]
      end
    end

    describe 'if workspace and scheme is given' do
      let(:branch) { sexp_find(sexp, [:else]) }

      before(:each) do
        data[:config][:xcode_workspace] = 'YourWorkspace.xcworkspace'
        data[:config][:xcode_scheme] = 'YourScheme'
      end

      it 'runs xcodebuild and xcpretty' do
        expect(branch).to include_sexp [:cmd, 'set -o pipefail && xcodebuild -workspace YourWorkspace.xcworkspace -scheme YourScheme build test | xcpretty', echo: true, timing: true]
      end

      it 'runs xctool for the xcode6.4 image' do
        data[:config][:osx_image] = 'xcode6.4'
        expect(branch).to include_sexp [:cmd, 'xctool -workspace YourWorkspace.xcworkspace -scheme YourScheme build test', echo: true, timing: true]
      end

      it 'runs xctool for the xcode7.3 image' do
        data[:config][:osx_image] = 'xcode7.3'
        expect(branch).to include_sexp [:cmd, 'xctool -workspace YourWorkspace.xcworkspace -scheme YourScheme build test', echo: true, timing: true]
      end
    end

    describe 'if project and scheme is given' do
      let(:branch) { sexp_find(sexp, [:else]) }

      before(:each) do
        data[:config][:xcode_project] = 'YourProject.xcodeproj'
        data[:config][:xcode_scheme] = 'YourScheme'
      end

      it 'runs xcodebuild and xcpretty' do
        expect(branch).to include_sexp [:cmd, 'set -o pipefail && xcodebuild -project YourProject.xcodeproj -scheme YourScheme build test | xcpretty', echo: true, timing: true]
      end

      it 'passes an SDK version to xcodebuild' do
        data[:config][:xcode_sdk] = '7.0'
        expect(branch).to include_sexp [:cmd, 'set -o pipefail && xcodebuild -project YourProject.xcodeproj -scheme YourScheme -sdk 7.0 build test | xcpretty', echo: true, timing: true]
      end

      it 'passes a destination to xcodebuild' do
        data[:config][:xcode_destination] = 'platform=iOS Simulator,name=iPhone X'
        expect(branch).to include_sexp [:cmd, 'set -o pipefail && xcodebuild -project YourProject.xcodeproj -scheme YourScheme -destination platform\=iOS\ Simulator,name\=iPhone\ X build test | xcpretty', echo: true, timing: true]
      end
    end

    describe 'if no settings are specified' do
      it 'prints a warning' do
        expect(sexp).to include_sexp [:cmd, "echo -e \"\\033[33;1mWARNING:\\033[33m Using Objective-C testing without specifying a scheme and either a workspace or a project is deprecated.\"", timing: true]
      end
    end
  end

  describe 'with cache enabled' do
    before { data[:config][:cache] = 'cocoapods' }

    it 'should add Poject/Podfile to directory cache' do
      script.directory_cache.expects(:add).with('./Pods')
      script.sexp
    end
  end

  describe 'when both cocoapods cache and bundler cache are enabled' do
    before { data[:config][:cache] = {'cocoapods' => true, 'bundler' => true } }

    it 'should add cocoapods and bundler to directory cache' do
      script.directory_cache.expects(:add).with('./Pods').at_least_once
      script.directory_cache.expects(:add).with('${BUNDLE_PATH:-./vendor/bundle}').at_least_once
      script.sexp
    end
  end
end
