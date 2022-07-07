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
        instance.stubs(:config).returns(vault: { secrets: %w[aaa/bbb] })
      end

      it 'sets @vault variable to vault value' do
        apply?

        expect(instance.instance_variable_get(:@vault)).to eq({ secrets: %w[aaa/bbb] })
      end

      it 'returns truthy value' do
        is_expected.to be_truthy
      end
    end

    context 'when there is no a vault in a config' do
      before do
        instance.stubs(:config).returns({ secrets: [] })
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

    context 'a normal scenario' do
      it do
        Travis::Vault::Keys.expects(:new).with(instance).returns(vault_keys)
        vault_keys.expects(:resolve)

        apply
      end
    end

    context 'when #resolve raises an error' do
      before do
        Travis::Vault::Keys.stubs(:new).with(instance).returns(vault_keys)
        vault_keys.stubs(:resolve).raises(Travis::Vault::RootKeyError)
        instance.stubs(:sh).returns(sh)
      end

      let(:sh) { stub('sh') }

      it do
        sh.expects(:echo).with('Too many keys in fetched data. Probably you provided the root key. Terminating for security reasons.', ansi: :red)
        sh.expects(:terminate)

        apply
      end
    end
  end
end
