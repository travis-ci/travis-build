require 'spec_helper'

describe Travis::Vault::Keys do
  describe '#resolve' do
    subject(:resolve) { described_class.new(vault, appliance).resolve }

    let(:vault) { stub(:vault) }
    let(:appliance) { stub(:appliance) }

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
