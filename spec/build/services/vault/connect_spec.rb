require 'spec_helper'

describe Travis::Vault::Connect do
  describe '#call' do
    subject(:call) { described_class.call }

    after do
      Travis::Vault::Config.instance.tap do |i|
        i.api_url = nil
        i.token = nil
      end
    end

    context 'the endpoint returns 200' do
      before do
        Travis::Vault::Config.instance.tap do |i|
          i.api_url = 'https://myvault.org'
          i.token = 'my-token'
        end

        stub_request(:get, 'https://myvault.org/v1/auth/token/lookup-self').
          with(headers: { 'X-Vault-Token' => 'my-token' }).
          to_return(status: 200)
      end

      it { expect { call }.not_to raise_error }
    end

    context 'the endpoint returns not-200' do
      before do
        Travis::Vault::Config.instance.tap do |i|
          i.api_url = 'https://myvault.org'
          i.token = 'my-token'
        end

        stub_request(:get, 'https://myvault.org/v1/auth/token/lookup-self').
          with(headers: { 'X-Vault-Token' => 'my-token' }).
          to_return(status: 403)
      end

      it { expect { call }.to raise_error(Travis::Vault::ConnectionError) }
    end

    context 'the endpoint is not correctly defined' do
      before do
        Travis::Vault::Config.instance.tap do |i|
          i.api_url = 'https:://myvault.org'
          i.token = 'my-token'
        end
      end

      it { expect { call }.to raise_error(URI::InvalidURIError) }
    end
  end
end
