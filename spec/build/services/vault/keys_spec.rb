require 'spec_helper'

describe Travis::Vault::Keys do
  describe '#resolve' do
    subject(:resolve) { described_class.new(appliance).resolve }

    let(:vault) { { api_url: 'https://my_vault.com', token: 'my_token' } }
    let(:appliance) { stub(vault: vault) }

    let(:paths) { stub(:paths) }
    let(:version) { stub(:version) }
    let(:resolver) { stub(call: nil) }

    it 'calls Resolver with proper parameters' do
      Travis::Vault::Keys::Version.expects(:call).with(vault).returns(version)
      Travis::Vault::Keys::Paths.expects(:call).with(vault).returns(paths)

      Travis::Vault::Keys::Resolver.expects(:new).with(paths, version, appliance).returns(resolver)
      resolver.expects(:call)

      resolve
    end
  end
end
