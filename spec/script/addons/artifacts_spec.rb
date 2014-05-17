require 'spec_helper'

describe Travis::Build::Script::Addons::Artifacts, focus: true do
  let(:script) { stub_everything('script') }

  before(:each) { script.stubs(:fold).yields(script) }

  subject { described_class.new(script, config) }

  context 'with a config' do
    let(:config) do
      {
        key: 'AZ1234',
        secret: 'BX12345678',
        bucket: 'hambone',
        private: true,
        max_size: 100 * 1024 * 1024,
        concurrency: 1000,
        target_paths: [
          'artifacts/$(go env GOOS)/$(go env GOARCH)/$TRAVIS_REPO_SLUG/' \
            '$TRAVIS_BUILD_NUMBER/$TRAVIS_JOB_NUMBER',
          'artifacts/$(go env GOOS)/$(go env GOARCH)/$TRAVIS_REPO_SLUG/' \
            '$TRAVIS_COMMIT'
        ]
      }
    end

    it 'exports ARTIFACTS_BUCKET' do
      script.expects(:if).with('($TRAVIS_PULL_REQUEST = false) && ($TRAVIS_BRANCH = master)').yields(script).once
      script.expects(:set).with('ARTIFACTS_BUCKET', 'hambone', echo: false,
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
        curl -sL https://raw.githubusercontent.com/meatballhat/artifacts/master/install | bash
      EOS
      subject.after_script
    end

    it 'prefixes $PATH with $HOME/bin' do
      script.expects(:if).with('($TRAVIS_PULL_REQUEST = false) && ($TRAVIS_BRANCH = master)').yields(script).once
      script.expects(:set).with('PATH', '$HOME/bin:$PATH', echo: false, assert: false).once
      subject.after_script
    end

    it 'runs the command' do
      script.expects(:if).with('($TRAVIS_PULL_REQUEST = false) && ($TRAVIS_BRANCH = master)').yields(script).once
      script.expects(:cmd).with('artifacts upload ', assert: false).once
      subject.after_script
    end

    it 'overwrites :concurrency' do
      script.expects(:if).with('($TRAVIS_PULL_REQUEST = false) && ($TRAVIS_BRANCH = master)').yields(script).once
      script.expects(:set).with('ARTIFACTS_CONCURRENCY', '5', echo: false, assert: false).once
      subject.after_script
    end

    it 'overwrites :max_size' do
      script.expects(:if).with('($TRAVIS_PULL_REQUEST = false) && ($TRAVIS_BRANCH = master)').yields(script).once
      script.expects(:set).with('ARTIFACTS_MAX_SIZE', "#{Float(5 * 1024 * 1024)}", echo: false, assert: false).once
      subject.after_script
    end
  end

  context 'with an invalid config' do
    let(:config) do
      {
        private: true,
        target_paths: [
          'artifacts/$(go env GOOS)/$(go env GOARCH)/$TRAVIS_REPO_SLUG/' \
            '$TRAVIS_BUILD_NUMBER/$TRAVIS_JOB_NUMBER',
          'artifacts/$(go env GOOS)/$(go env GOARCH)/$TRAVIS_REPO_SLUG/' \
            '$TRAVIS_COMMIT'
        ]
      }
    end

    it 'echoes a message about missing :key' do
      script.expects(:if).with('($TRAVIS_PULL_REQUEST = false) && ($TRAVIS_BRANCH = master)').yields(script).once
      script.expects(:cmd).with('echo "Artifacts config missing :key param"', echo: false, assert: false).once
      subject.after_script
    end

    it 'echoes a message about missing :secret' do
      script.expects(:if).with('($TRAVIS_PULL_REQUEST = false) && ($TRAVIS_BRANCH = master)').yields(script).once
      script.expects(:cmd).with('echo "Artifacts config missing :secret param"', echo: false, assert: false).once
      subject.after_script
    end

    it 'echoes a message about missing :bucket' do
      script.expects(:if).with('($TRAVIS_PULL_REQUEST = false) && ($TRAVIS_BRANCH = master)').yields(script).once
      script.expects(:cmd).with('echo "Artifacts config missing :bucket param"', echo: false, assert: false).once
      subject.after_script
    end

    it 'aborts before running anything' do
      script.expects(:if).with('($TRAVIS_PULL_REQUEST = false) && ($TRAVIS_BRANCH = master)').yields(script).once
      subject.expects(:install).never
      subject.expects(:configure_env).never
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
