require 'spec_helper'

describe Travis::Vault::Keys::KV1 do
  describe '.resolve' do
    subject { described_class.resolve(path) }

    before do
      Travis::Vault::Config.instance.tap do |i|
        i.api_url = 'https://myvault.org'
        i.token = 'my-token'
      end
    end

    after do
      Travis::Vault::Config.instance.tap do |i|
        i.api_url = nil
        i.token = nil
      end
    end

    let(:path) { 'path/to/variable' }

    context 'when the response code is 200' do
      before do
        stub_request(:get, 'https://myvault.org/v1/secret/path/to/variable').
          with(headers: { 'X-Vault-Token' => 'my-token' }).
          to_return(status: 200, body: { data: { my_data: { b: '123' } } }.to_json)
      end

      it do
        is_expected.to eq({ 'my_data' => { 'b' => '123' } }.to_json)
      end
    end

    context 'when the response code is not 200' do
      before do
        stub_request(:get, 'https://myvault.org/v1/secret/path/to/variable').
          with(headers: { 'X-Vault-Token' => 'my-token' }).
          to_return(status: 404, body: '<html></html>')
      end

      it 'does not explode' do
        is_expected.to be_nil
      end
    end
  end
end
