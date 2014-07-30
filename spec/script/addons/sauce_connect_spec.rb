require 'spec_helper'

describe Travis::Build::Script::Addons::SauceConnect do
  let(:script) { stub_everything('script') }
  let(:command) do
    'echo -e "\033[33;1mStarting Sauce Connect\033[0m"; ' +
    'echo "curl -L https://gist.githubusercontent.com/santiycr/5139567/raw/sauce_connect_setup.sh | bash"; ' +
    'curl -L https://gist.githubusercontent.com/santiycr/5139565/raw/sauce_connect_setup.sh | bash'
  end

  before(:each) { script.stubs(:fold).yields(script) }

  subject { described_class.new(script, config).before_script }

  context 'without credentials' do
    let(:config) { true }

    it 'runs the command' do
      script.expects(:fold).with('sauce_connect').yields(script)
      script.expects(:echo).with('Starting Sauce Connect', ansi: :yellow)
      script.expects(:cmd).with('curl -L https://gist.githubusercontent.com/henrikhodne/9322897/raw/sauce-connect.sh | bash', assert: false)
      subject
    end

    it 'exports TRAVIS_SAUCE_CONNECT' do
      script.expects(:set).with('TRAVIS_SAUCE_CONNECT', 'true', echo: false)
      subject
    end
  end

  context 'with username and access key' do
    let(:config) { { :username => 'johndoe', :access_key => '0123456789abcfdef' } }

    it 'exports the username' do
      script.expects(:set).with('SAUCE_USERNAME', 'johndoe', echo: false)
      subject
    end

    it 'exports the access key' do
      script.expects(:set).with('SAUCE_ACCESS_KEY', '0123456789abcfdef', echo: false)
      subject
    end

    it 'runs the command' do
      script.expects(:fold).with('sauce_connect').yields(script)
      script.expects(:echo).with('Starting Sauce Connect', ansi: :yellow)
      script.expects(:cmd).with('curl -L https://gist.githubusercontent.com/henrikhodne/9322897/raw/sauce-connect.sh | bash', assert: false)
      subject
    end

    it 'exports TRAVIS_SAUCE_CONNECT' do
      script.expects(:set).with('TRAVIS_SAUCE_CONNECT', 'true', echo: false)
      subject
    end
  end
end
