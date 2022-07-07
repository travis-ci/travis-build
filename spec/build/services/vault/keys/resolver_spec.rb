require 'spec_helper'

describe Travis::Vault::Keys::Resolver do
  describe '#call' do
    subject(:call) { instance.call }

    let(:instance) { described_class.new(paths, 'kv2', appliance) }

    let(:sh) { stub('sh') }

    let(:vault) { stub('vault') }

    let(:appliance) { stub(sh: sh, vault: vault) }

    context 'when paths are empty' do
      let(:paths) { [] }

      it 'does not call Vault' do
        Travis::Vault::Keys::KV2.expects(:resolve).never

        call
      end
    end

    context 'when paths are not empty' do
      let(:paths) { ['path/to/something/secret_thing'] }

      context 'when path returns value from Vault' do
        it do
          Travis::Vault::Keys::KV2.expects(:resolve).with(paths.first, vault).returns({ my_key: 'MySecretValue' }.to_json)
          sh.expects(:echo).never
          sh.expects(:export).with('SECRET_THING', "'{\"my_key\":\"MySecretValue\"}'", echo: true, secure: true)

          call
        end
      end

      context 'when path does not returns value from Vault' do

        it do
          Travis::Vault::Keys::KV2.expects(:resolve).with(paths.first, vault).returns(nil)
          sh.expects(:export).never
          sh.expects(:echo).with('The value fetched for path/to/something/secret_thing is blank.', ansi: :yellow)

          call
        end
      end
    end
  end
end
