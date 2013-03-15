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
end
