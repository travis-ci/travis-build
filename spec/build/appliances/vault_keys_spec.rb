require 'spec_helper'

describe Travis::Build::Appliances::VaultKeys do
  let(:instance) { described_class.new }

  describe '#vault' do
    it do
      expect(instance.respond_to?(:vault)).to be(true)
    end
  end

  describe '#apply?' do
    subject(:apply?) { instance.apply? }

    context 'when there is a vault in a config' do
      before do
        instance.stubs(:config).returns(vault: { secures: [] })
      end

      it 'sets @vault variable to vault value' do
        apply?

        expect(instance.instance_variable_get(:@vault)).to eq({ secures: [] })
      end

      it 'returns truthy value' do
        is_expected.to be_truthy
      end
    end

    context 'when there is no a vault in a config' do
      before do
        instance.stubs(:config).returns({})
      end

      it 'sets @vault variable nil' do
        apply?

        expect(instance.instance_variable_get(:@vault)).to eq(nil)
      end

      it 'returns falsey value' do
        is_expected.to be_falsey
      end
    end
  end

  describe '#apply' do
    subject(:apply) { instance.apply }

    let(:vault_keys) { stub(:vault_keys) }

    it do
      Travis::Vault::Keys.expects(:new).with(instance).returns(vault_keys)
      vault_keys.expects(:resolve)

      apply
    end
  end
end
