require 'spec_helper'

describe Travis::Build::Script::Generic do
  let(:options) { { logs: { build: false, state: false } } }
  let(:data)    { PAYLOADS[:push].deep_clone }

  subject { described_class.new(data, options).compile }

  it 'sets up Sauce Connect correctly' do
    data['config']['addons'] = {
      'sauce_connect' => {
        'username' => 'johndoe',
        'access_key' => '0123456789abcdef',
      }
    }

    subject
    store_example 'addons_sauce_connect'
  end

  it 'sets up Firefox correctly' do
    data['config']['addons'] = { 'firefox' => '20.0' }

    subject
    store_example 'addons_firefox'
  end

  it "sets up the hosts file" do
    data["config"]["addons"] = { "hosts" => "johndoe.local" }

    subject
    store_example "addons_hosts"
  end

  it "runs the addons even if the stage isn't specified in the config" do
    data['config'].delete('before_script')
    data['config']['addons'] = {
      'sauce_connect' => {
        'username' => 'johndoe',
        'access_key' => '0123456789abcdef',
      }
    }

    subject

    should set 'SAUCE_USERNAME', 'johndoe'
  end

  it "doesn't fail with an unknown addon" do
    data['config']['addons'] = { 'empty' => 'something' }
    expect {
      subject
    }.not_to raise_error
  end
end
