# vim:set ts=2 sw=2 sts=2 autoindent:

require 'spec_helper'

describe Travis::Build::Script::Dart, :sexp do
  let(:data)   { payload_for(:push, :dart) }
  let(:script) { described_class.new(data) }
  subject      { script.sexp }
  it           { store_example }

  it_behaves_like 'a bash script'
  it_behaves_like 'a build script sexp'

  it 'sets TRAVIS_DART_VERSION' do
    should include_sexp [:export, ['TRAVIS_DART_VERSION', 'stable']]
  end

  it 'sets DART_SDK' do
    should include_sexp [:cmd, %r(export DART_SDK=.*), assert: true,
      echo: true, timing: true]
  end

  it "announces `dart --version`" do
    should include_sexp [:cmd, "dart --version", echo: true]
  end

  it "does not install content_shell by default" do
    should_not include_sexp [:echo, "Installing Content Shell dependencies",
      ansi: :yellow]
    should_not include_sexp [:echo, "Installing Content Shell", ansi: :yellow]
  end

  it "runs tests by default" do
    should include_sexp [:cmd,
      "pub global run test_runner --disable-ansi --skip-browser-tests",
      echo: true, timing: true]
  end

  describe 'installs content_shell if config has a :with_content_shell key set with true' do
    before do
      data[:config][:with_content_shell] = true
    end

    it "installs content_shell" do
      should include_sexp [:echo, "Installing Content Shell dependencies",
        ansi: :yellow]
      should include_sexp [:echo, "Installing Content Shell", ansi: :yellow]
    end
  end

  describe 'archive_url for' do
    describe 'stable' do
      before { data[:config][:dart] = 'stable' }
      it 'is https://storage.googleapis.com/dart-archive/channels/stable/release/latest' do
        expect(subject.flatten.join).to include('https://storage.googleapis.com/dart-archive/channels/stable/release/latest')
      end
    end

    describe 'dev' do
      before { data[:config][:dart] = 'dev' }
      it 'is https://storage.googleapis.com/dart-archive/channels/dev/release/latest' do
        expect(subject.flatten.join).to include('https://storage.googleapis.com/dart-archive/channels/dev/release/latest')
      end
    end

    describe 'be/raw/110749' do
      before { data[:config][:dart] = 'be/raw/110749' }
      it 'is https://storage.googleapis.com/dart-archive/channels/be/raw/110749' do
        expect(subject.flatten.join).to include('https://storage.googleapis.com/dart-archive/channels/be/raw/110749')
      end
    end

    describe '1.16.0-dev.2.0' do
      before { data[:config][:dart] = '1.16.0-dev.2.0' }
      it 'is https://storage.googleapis.com/dart-archive/channels/dev/release/1.16.0-dev.2.0' do
        expect(subject.flatten.join).to include('https://storage.googleapis.com/dart-archive/channels/dev/release/1.16.0-dev.2.0')
      end
    end

    describe '1.14.1' do
      before { data[:config][:dart] = '1.14.1' }
      it 'is https://storage.googleapis.com/dart-archive/channels/stable/release/1.14.1' do
        expect(subject.flatten.join).to include('https://storage.googleapis.com/dart-archive/channels/stable/release/1.14.1')
      end
    end
  end

  describe 'script' do
    describe 'with with_content_shell' do
      before { data[:config][:with_content_shell] = true }

      it 'should have a deprecation message' do
        should include_deprecation_sexp(/with_content_shell is deprecated/)
      end

      describe 'with dart_task being set' do
        before { data[:config][:dart_task] = {test: true} }
        it 'should fail' do
          should include_sexp [:echo, "with_content_shell can't be used with dart_task."]
        end
      end

      describe 'with install_dartium being true' do
        before { data[:config][:install_dartium] = true }
        it 'should fail' do
          should include_sexp [:echo, "with_content_shell can't be used with install_dartium."]
        end
      end

      describe 'with xvfb being false' do
        before { data[:config][:xvfb] = false }
        it 'should fail' do
          should include_sexp [:echo, "with_content_shell can't be used with xvfb."]
        end
      end
    end

    describe 'with install_dartium' do
      before { data[:config][:install_dartium] = true }

      describe 'on Linux' do
        before { data[:config][:os] = 'linux' }

        it 'downloads the Linux archive' do
          should match_sexp [:cmd, %r{dartium/dartium-linux-x64-release.zip}]
        end

        it 'links to the chrome executable' do
          should match_sexp [:cmd, %r{ln -s ".*/chrome" dartium}]
        end
      end

      describe 'on OS X' do
        before { data[:config][:os] = 'osx' }

        it 'downloads the OS X archive' do
          should match_sexp [:cmd, %r{dartium/dartium-macos-x64-release.zip}]
        end

        it 'links to the Chromium executable' do
          should match_sexp [:cmd, %r{ln -s ".*/Chromium\.app/Contents/MacOS/Chromium" dartium}]
        end
      end
    end

    describe 'if a directory packages/test exists or the file .packages defines a test [something ... target?]' do
      let(:sexp) { sexp_find(subject, [:if, "[[ -d packages/test ]] || grep -q ^test: .packages 2> /dev/null"]) }

      # TODO this should be tested as part of a general spec for shell/builder, which does not exist atm
      it 'specifies the condition as raw bash' do
        expect(sexp.last).to eq(raw: true)
      end

      describe 'with with_content_shell being true' do
        let(:sexp) { sexp_filter(super(), [:then]) }
        before     { data[:config][:with_content_shell] = true }

        it 'exports DISPLAY=:99:0' do
          expect(sexp).to include_sexp [:export, ['DISPLAY', ':99.0'], echo: true]
        end

        it 'starts xvfb' do
          expect(sexp).to include_sexp [:cmd, 'sh -e /etc/init.d/xvfb start', echo: true, timing: true]
        end

        it 'runs pub run test -p vm -p content-shell -p firefox' do
          expect(sexp).to include_sexp [:cmd, 'pub run test -p vm -p content-shell -p firefox', echo: true, timing: true]
        end
      end

      describe 'with with_content_shell being nil' do
        let(:sexp) { sexp_filter(super(), [:then]) }

        it 'runs pub run test with XVFB' do
          expect(sexp).to include_sexp [:cmd, 'xvfb-run -s "-screen 0 1024x768x24" pub run test', echo: true, timing: true]
        end

        describe 'with test args' do
          before { data[:config][:dart_task] = {test: '--platform chrome'} }
          it "runs pub run test with those arguments" do
            expect(sexp).to match_sexp [:cmd, /pub run test --platform chrome/]
          end
        end

        describe 'with xvfb being false' do
          before { data[:config][:xvfb] = false }
          it "runs pub run test without XVFB" do
            expect(sexp).to include_sexp [:cmd, 'pub run test', echo: true, timing: true]
          end
        end

        describe 'with a different task specified' do
          before { data[:config][:dart_task] = 'dartanalyzer' }
          it "doesn't run pub run test" do
            expect(sexp).not_to match_sexp [:cmd, /pub run test/]
          end
        end
      end
    end

    describe 'if a directory packages/unittest exists or the file .packages defines a unittest [something ... target?]' do
      let(:sexp) { sexp_find(subject, [:elif, "[[ -d packages/unittest ]] || grep -q ^unittest: .packages 2> /dev/null"]) }

      # TODO this should be tested as part of a general spec for shell/builder, which does not exist atm
      it 'specifies the condition as raw bash' do
        expect(sexp.last).to eq(raw: true)
      end

      it 'installs the test runner' do
        expect(sexp).to include_sexp [:cmd, 'pub global activate test_runner', echo: true, timing: true]
      end

      describe 'with with_content_shell being true' do
        before { data[:config][:with_content_shell] = true }

        it 'runs pub global run test_runner via xvfb-run' do
          expect(sexp).to include_sexp [:cmd, 'xvfb-run -s "-screen 0 1024x768x24" pub global run test_runner --disable-ansi', echo: true, timing: true]
        end
      end

      describe 'with with_content_shell being nil' do
        it 'runs pub run test' do
          expect(sexp).to include_sexp [:cmd, 'pub global run test_runner --disable-ansi --skip-browser-tests', echo: true, timing: true]
        end
      end
    end

    describe 'with dartanalyzer' do
      before { data[:config][:dart_task] = 'dartanalyzer' }

      it "runs dartanalyzer on the whole package" do
        should include_sexp [:cmd, 'dartanalyzer .', echo: true, timing: true]
      end

      describe 'with arguments' do
        before { data[:config][:dart_task] = {dartanalyzer: '--fatal-warnings lib'} }

        it "runs dartanalyzer with those arguments" do
          should include_sexp [:cmd, 'dartanalyzer --fatal-warnings lib', echo: true, timing: true]
        end
      end
    end

    describe 'with dartfmt' do
      before { data[:config][:dart_task] = 'dartfmt' }

      describe 'when dart_style is installed but dartfmt: sdk is not specified' do
        let(:sexp) { sexp_find(subject, [:elif, "[[ -f pubspec.yaml ]] && (pub deps | grep -q \"^[|']-- dart_style \")"]) }
        it "runs the installed version of dartfmt" do
          should include_sexp [:raw, 'function dartfmt() { pub run dart_style:format "$@"; }']
        end
      end

      describe 'when dart_style is installed but darfmt: sdk is specified' do
        before { data[:config][:dart_task] = {dartfmt: 'sdk'} }
        let(:sexp) { sexp_find(subject, [:elif, "[[ -f pubspec.yaml ]] && (pub deps | grep -q \"^[|']-- dart_style \")"]) }
        it "runs the SDK version of dartfmt" do
          should match_sexp [:cmd, /dartfmt -n \./]
        end
      end

      it 'runs dartfmt -n on the whole package' do
        should match_sexp [:cmd, /dartfmt -n \./]
      end
    end
  end
end
