require 'spec_helper'

describe Travis::Vault::Connect do
  describe '#call' do
    subject(:call) { described_class.call(vault) }

    let(:vault) do
      {
        api_url: 'https://myvault.org',
        token: 'my-token'
      }
    end

    context 'the endpoint returns 200' do
      before do
        stub_request(:get, 'https://myvault.org/v1/auth/token/lookup-self').
          with(headers: { 'X-Vault-Token': 'my-token' }).
          to_return(status: 200)
      end

      it { expect { call }.not_to raise_error }
    end

    context 'the endpoint returns not-200' do
      before do
        stub_request(:get, 'https://myvault.org/v1/auth/token/lookup-self').
          with(headers: { 'X-Vault-Token': 'my-token' }).
          to_return(status: 403)
      end

      it { expect { call }.to raise_error(Travis::Vault::ConnectionError) }
    end

    context 'the endpoint is not correctly defined' do
      it { expect { call }.to raise_error(Travis::Vault::ConnectionError) }
    end
  end
end
