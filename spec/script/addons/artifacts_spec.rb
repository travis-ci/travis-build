require 'spec_helper'

describe Travis::Build::Script::Addons::Artifacts do
  let(:script) { stub_everything('script') }

  before(:each) { script.stubs(:fold).yields(script) }

  subject { described_class.new(script, config) }

  context 'with a config' do
    let(:config) do
      {
        s3_bucket: 'hambone',
        private: true,
        target_paths: [
          'artifacts/$(go env GOOS)/$(go env GOARCH)/$TRAVIS_REPO_SLUG/' \
            '$TRAVIS_BUILD_NUMBER/$TRAVIS_JOB_NUMBER',
          'artifacts/$(go env GOOS)/$(go env GOARCH)/$TRAVIS_REPO_SLUG/' \
            '$TRAVIS_COMMIT'
        ]
      }
    end

    it 'exports ARTIFACTS_S3_BUCKET' do
      script.expects(:if).with('($TRAVIS_PULL_REQUEST = false) && ($TRAVIS_BRANCH = master)').yields(script).once
      script.expects(:set).with('ARTIFACTS_S3_BUCKET', 'hambone', echo: false,
                                assert: false)
      subject.after_script
    end

    it 'exports ARTIFACTS_PRIVATE' do
      script.expects(:if).with('($TRAVIS_PULL_REQUEST = false) && ($TRAVIS_BRANCH = master)').yields(script).once
      script.expects(:set).with('ARTIFACTS_PRIVATE', 'true', echo: false,
                                assert: false)
      subject.after_script
    end

    it 'exports ARTIFACTS_TARGET_PATHS' do
      script.expects(:if).with('($TRAVIS_PULL_REQUEST = false) && ($TRAVIS_BRANCH = master)').yields(script).once
      script.expects(:set).with(
        'ARTIFACTS_TARGET_PATHS',
        'artifacts/$(go env GOOS)/$(go env GOARCH)/$TRAVIS_REPO_SLUG/' \
          '$TRAVIS_BUILD_NUMBER/$TRAVIS_JOB_NUMBER;' \
        'artifacts/$(go env GOOS)/$(go env GOARCH)/$TRAVIS_REPO_SLUG/' \
          '$TRAVIS_COMMIT',
        echo: false, assert: false
      )
      subject.after_script
    end

    it 'installs artifacts' do
      script.expects(:if).with('($TRAVIS_PULL_REQUEST = false) && ($TRAVIS_BRANCH = master)').yields(script).once
      script.expects(:cmd).with(<<-EOS.strip.gsub(/\s+/, ' '), echo: false, assert: false).once
        artifacts -v || curl -sL https://raw.githubusercontent.com/meatballhat/artifacts/master/install | bash
      EOS
      subject.after_script
    end

    it 'runs the command' do
      script.expects(:if).with('($TRAVIS_PULL_REQUEST = false) && ($TRAVIS_BRANCH = master)').yields(script).once
      script.expects(:cmd).with('artifacts upload ', echo: false, assert: false).once
      subject.after_script
    end
  end

  context 'without a config' do
    let(:config) { {} }

    it "doesn't do anything" do
      script.expects(:set).never
      script.expects(:cmd).never
      script.expects(:if).never
      script.expects(:fold).never
      subject.after_script
    end
  end
end
