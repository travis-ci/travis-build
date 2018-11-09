require 'spec_helper'

describe Travis::Build::Addons::Browserstack, :sexp do
  let(:script) { stub('script') }
  let(:config) { { access_key: 'accesskey' } }
  let(:data)   { payload_for(:push, :ruby, config: { addons: { browserstack: config } }) }
  let(:sh)     { Travis::Shell::Builder.new }
  let(:addon)  { described_class.new(script, sh, Travis::Build::Data.new(data), config) }
  subject      { sh.to_sexp }
  before       { addon.before_before_script }

  shared_examples_for 'installs browserstack local' do
    zip_package = "#{described_class::BROWSERSTACK_BIN_FILE}-linux-x64.zip"
    it { should include_sexp [:echo, "Installing BrowserStack Local", ansi: :yellow] }
    it { should include_sexp [:cmd, "mkdir -p #{described_class::BROWSERSTACK_HOME}"] }
    it { should include_sexp [:cmd, "wget -O /tmp/#{zip_package} #{described_class::BROWSERSTACK_BIN_URL}/#{zip_package}", echo: true, timing: true, retry: true] }
    it { should include_sexp [:cmd, "unzip -d #{described_class::BROWSERSTACK_HOME}/ /tmp/#{zip_package} 2>&1 > /dev/null"] }
    it { should include_sexp [:chmod, ["+x", "#{described_class::BROWSERSTACK_HOME}/BrowserStackLocal"]] }

    it 'sets BROWSERSTACK_ACCESS_KEY and BROWSERSTACK_LOCAL' do
      should include_sexp [:export, ["#{described_class::ENV_KEY}", config[:access_key]]]
      should include_sexp [:export, ["#{described_class::ENV_LOCAL}", 'true'], {:echo => true}]
    end
  end

  describe 'without access_key' do
    let(:config) { {} }

    it { should include_sexp [:echo, "Browserstack access_key is invalid.", ansi: :red] }
  end

  describe 'with access_key' do
    let(:config) { { os: 'linux', access_key: 'accesskey' } }

    it_behaves_like 'installs browserstack local'
    it { should include_sexp [:cmd, "#{described_class::BROWSERSTACK_HOME}/BrowserStackLocal -d start #{config[:access_key]} -localIdentifier $BROWSERSTACK_LOCAL_IDENTIFIER"] }
  end

  describe 'with username and access_key' do
    let(:config) { { os: 'linux', username: 'user1', access_key: 'accesskey' } }

    it_behaves_like 'installs browserstack local'
    it { should include_sexp [:export, ["#{described_class::ENV_USER}", config[:username] + "-travis"], {:echo => true}] }
    it { should include_sexp [:cmd, "#{described_class::BROWSERSTACK_HOME}/BrowserStackLocal -d start #{config[:access_key]} -localIdentifier $BROWSERSTACK_LOCAL_IDENTIFIER"] }
  end

  describe 'with access_key and folder path' do
    let(:config) { { os: 'linux', access_key: 'accesskey', folder: 'path/to/user/folder' } }

    it_behaves_like 'installs browserstack local'
    it { should include_sexp [:cmd, "#{described_class::BROWSERSTACK_HOME}/BrowserStackLocal -d start #{config[:access_key]} -localIdentifier $BROWSERSTACK_LOCAL_IDENTIFIER -f #{config[:folder]}"] }
  end

  describe 'with access_key and force_local' do
    let(:config) { { os: 'linux', access_key: 'accesskey', force_local: true } }

    it_behaves_like 'installs browserstack local'
    it { should include_sexp [:cmd, "#{described_class::BROWSERSTACK_HOME}/BrowserStackLocal -d start #{config[:access_key]} -localIdentifier $BROWSERSTACK_LOCAL_IDENTIFIER -forcelocal"] }
  end

  describe 'with access_key and local_identifier' do
    let(:config) { { os: 'linux', access_key: 'accesskey', local_identifier: '123' } }

    it_behaves_like 'installs browserstack local'
    it { should include_sexp [:export, ["#{described_class::ENV_LOCAL_IDENTIFIER}", config[:local_identifier]], {:echo=>true}] }
    it { should include_sexp [:cmd, "#{described_class::BROWSERSTACK_HOME}/BrowserStackLocal -d start #{config[:access_key]} -localIdentifier #{config[:local_identifier]}"] }
  end

  describe 'with access_key and proxy settings' do
    let(:config) { { os: 'linux', access_key: 'accesskey', proxy_host: 'localhost', proxy_port: 1234 } }

    it_behaves_like 'installs browserstack local'
    it { should include_sexp [:cmd, "#{described_class::BROWSERSTACK_HOME}/BrowserStackLocal -d start #{config[:access_key]} -localIdentifier $BROWSERSTACK_LOCAL_IDENTIFIER -proxyHost #{config[:proxy_host]} -proxyPort #{config[:proxy_port]}"] }
  end

  describe 'with access_key and proxy settings with credentials' do
    let(:config) { { os: 'linux', access_key: 'accesskey', proxy_host: 'localhost', proxy_port: 1234, proxy_user: 'user', proxy_pass: 'pass' } }

    it_behaves_like 'installs browserstack local'
    it { should include_sexp [:cmd, "#{described_class::BROWSERSTACK_HOME}/BrowserStackLocal -d start #{config[:access_key]} -localIdentifier $BROWSERSTACK_LOCAL_IDENTIFIER -proxyHost #{config[:proxy_host]} -proxyPort #{config[:proxy_port]} -proxyUser #{config[:proxy_user]} -proxyPass #{config[:proxy_pass]}"] }
  end

  describe 'with app path' do
    let(:config) { { os: 'linux', username: 'user1', access_key: 'accesskey', app_path: 'some/path' } }

    it_behaves_like 'installs browserstack local'
    it { should include_sexp [:export, ["#{described_class::ENV_USER}", config[:username] + "-travis"], {:echo => true}] }
    it { should include_sexp [:cmd, "curl -u \"#{config[:username]}:#{config[:access_key]}\" -X POST #{described_class::BROWSERSTACK_APP_AUTOMATE_URL} -F \"file=@$TRAVIS_BUILD_DIR/#{config[:app_path]}\" | tee $TRAVIS_BUILD_DIR/app_upload_out"] }
    it { should include_sexp [:export, ["#{described_class::ENV_APP_ID}", "`cat $TRAVIS_BUILD_DIR/app_upload_out | jq -r .app_url`"], {:echo => true} ] }
    it { should include_sexp [:export, ["#{described_class::ENV_CUSTOM_ID}", "`cat $TRAVIS_BUILD_DIR/app_upload_out | jq -r .custom_id`"], {:echo => true}] }
    it { should include_sexp [:export, ["#{described_class::ENV_SHAREABLE_ID}", "`cat $TRAVIS_BUILD_DIR/app_upload_out | jq -r .shareable_id`"], {:echo => true}] }
  end
end
