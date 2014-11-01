require 'spec_helper'

describe Travis::Build::Script::ObjectiveC, :sexp do
  let(:data)   { PAYLOADS[:push].deep_clone }
  let(:script) { described_class.new(data) }
  let(:is_ruby_motion) { "-f Rakefile && \"$(cat Rakefile)\" =~ require\\ [\\\"\\']motion/project" }
  subject      { script.sexp }

  describe 'announce' do
    let(:sexp) { sexp_find(subject, [:if, is_ruby_motion]) }

    it 'announces xcodebuild -version -sdk' do
      should include_sexp [:cmd, 'xcodebuild -version -sdk', echo: true]
    end

    it 'announces RubyMotion version if project is a RubyMotion project' do
      branch = sexp_find(sexp, [:then])
      expect(branch).to include_sexp [:cmd, 'motion --version', echo: true]
    end

    it 'announces CocoaPods version if a Podfile exists' do
      branch = sexp_find(sexp, [:elif, '-f Podfile'])
      expect(branch).to include_sexp [:cmd, 'pod --version', echo: true]
    end
  end

  describe 'setup' do
    it 'handles ruby version being set' do
      data['config']['rvm'] = 'system'
      should include_sexp [:cmd, 'rvm use system --install --binary --fuzzy', echo: true, timing: true, assert: true]
    end
  end

  describe 'export' do
    it 'sets TRAVIS_XCODE_SDK' do
      data['config']['xcode_sdk'] = 'iphonesimulator7.0'
      should include_sexp [:export, ['TRAVIS_XCODE_SDK', 'iphonesimulator7.0']]
    end

    it 'sets TRAVIS_XCODE_SCHEME' do
      data['config']['xcode_scheme'] = 'MyTests'
      should include_sexp [:export, ['TRAVIS_XCODE_SCHEME', 'MyTests']]
    end

    it 'sets TRAVIS_XCODE_PROJECT' do
      data['config']['xcode_project'] = 'MyProject.xcodeproj'
      should include_sexp [:export, ['TRAVIS_XCODE_PROJECT', 'MyProject.xcodeproj']]
    end

    it 'sets TRAVIS_XCODE_WORKSPACE' do
      data['config']['xcode_workspace'] = 'MyWorkspace.xcworkspace'
      should include_sexp [:export, ['TRAVIS_XCODE_WORKSPACE', 'MyWorkspace.xcworkspace']]
    end
  end

  describe 'install' do
    it 'runs bundle install if the project is a RubyMotion project' do
      sexp = sexp_find(subject, [:elif, '-f Gemfile'])
      expect(sexp).to include_sexp [:cmd, 'bundle install --jobs=3 --retry=3', echo: true, timing: true, assert: true, retry: true]
    end

    it 'runs pod install if a Podfile exists' do
      sexp = sexp_find(subject, [:if, '-f Podfile'])
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
      before(:each) do
        data['config']['xcode_workspace'] = 'YourWorkspace.xcworkspace'
        data['config']['xcode_scheme'] = 'YourScheme'
      end

      it 'runs xctool' do
        branch = sexp_find(sexp, [:else])
        expect(branch).to include_sexp [:cmd, 'xctool -workspace YourWorkspace.xcworkspace -scheme YourScheme build test', echo: true, timing: true]
      end
    end

    describe 'if project and scheme is given' do
      let(:branch) { sexp_find(sexp, [:else]) }

      before(:each) do
        data['config']['xcode_project'] = 'YourProject.xcodeproj'
        data['config']['xcode_scheme'] = 'YourScheme'
      end

      it 'runs xctool' do
        expect(branch).to include_sexp [:cmd, 'xctool -project YourProject.xcodeproj -scheme YourScheme build test', echo: true, timing: true]
      end

      it 'passes an SDK version to xctool' do
        data['config']['xcode_sdk'] = '7.0'
        expect(branch).to include_sexp [:cmd, 'xctool -project YourProject.xcodeproj -scheme YourScheme -sdk 7.0 build test', echo: true, timing: true]
      end
    end

    describe 'if no settings are specified' do
      it 'prints a warning' do
        subject
        # should include_deprecation_sexp(/without specifying a scheme and either a workspace or a project/)
      end
    end
  end
end
