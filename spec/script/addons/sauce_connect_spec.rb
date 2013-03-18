require 'spec_helper'

describe Travis::Build::Script::Addons::SauceConnect do
  let(:script) { stub_everything('script') }

  subject { described_class.new(script, config).run }

  context 'without credentials' do
    let(:config) { true }

    it 'runs the command' do
      script.expects(:cmd).with('curl https://gist.github.com/santiycr/5139565/raw/sauce_connect_setup.sh | bash', assert: false, fold: 'sauce_connect')
      subject
    end

    it 'exports TRAVIS_SAUCE_CONNECT' do
      script.expects(:set).with('TRAVIS_SAUCE_CONNECT', 'true', echo: false, assert: false)
      subject
    end
  end

  context 'with username and access key' do
    let(:config) { { :username => 'johndoe', :access_key => '0123456789abcfdef' } }

    it 'exports the username' do
      script.expects(:set).with('SAUCE_USERNAME', 'johndoe', echo: false, assert: false)
      subject
    end

    it 'exports the access key' do
      script.expects(:set).with('SAUCE_ACCESS_KEY', '0123456789abcfdef', echo: false, assert: false)
      subject
    end

    it 'runs the command' do
      script.expects(:cmd).with('curl https://gist.github.com/santiycr/5139565/raw/sauce_connect_setup.sh | bash', assert: false, fold: 'sauce_connect')
      subject
    end

    it 'exports TRAVIS_SAUCE_CONNECT' do
      script.expects(:set).with('TRAVIS_SAUCE_CONNECT', 'true', echo: false, assert: false)
      subject
    end
  end
end
