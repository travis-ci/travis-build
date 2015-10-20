# vim:set ts=2 sw=2 sts=2 autoindent:

require 'spec_helper'

describe Travis::Build::Script::Dart, :sexp do
  let(:data)   { payload_for(:push, :dart) }
  let(:script) { described_class.new(data) }
  subject      { script.sexp }

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
      data[:config][:with_content_shell] = 'true'
    end

    it "installs content_shell" do
      should include_sexp [:echo, "Installing Content Shell dependencies",
        ansi: :yellow]
      should include_sexp [:echo, "Installing Content Shell", ansi: :yellow]
    end
  end

  describe 'script' do
    describe 'if a directory packages/test exists or the file .packages defines a test [something ... target?]' do
      let(:sexp) { sexp_find(subject, [:if, "[[ -d packages/test ]] || grep -q ^test: .packages 2> /dev/null"]) }

      # TODO this should be tested as part of a general spec for shell/builder, which does not exist atm
      it 'specifies the condition as raw bash' do
        expect(sexp.last).to eq(raw: true)
      end

      describe 'with with_content_shell being true' do
        let(:sexp) { sexp_filter(super(), [:then]) }
        before     { data[:config][:with_content_shell] = 'true' }

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

        it 'runs pub run test' do
          expect(sexp).to include_sexp [:cmd, 'pub run test', echo: true, timing: true]
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
        before { data[:config][:with_content_shell] = 'true' }

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
  end
end
