require 'spec_helper'

describe Travis::Vault::Keys::Resolver do
  describe '#call' do
    let(:sh) { stub('sh') }
    let(:vault) { stub('vault') }
    let(:data) { stub('data') }
    let(:appliance) { stub(sh: sh, vault: vault, data: data) }
    let(:instance) { described_class.new(paths, 'kv2', appliance) }

    subject(:call) { instance.call }

    context 'when paths are empty' do
      let(:paths) { [] }

      it 'does not call Vault' do
        Travis::Vault::Keys::KV2.expects(:resolve).never

        call
      end
    end

    context 'when paths are not empty' do
      let(:paths) { %w[path/to/something/secret_thing another/secret_thing another/secret_thing] }

      before do
        Travis::Vault::Keys::KV2.stubs(:resolve).with(nil, 'path', paths.first.split('/',2).last, vault).returns({ my_key: 'MySecretValue' })
        Travis::Vault::Keys::KV2.stubs(:resolve).with(nil, 'another', paths[1].split('/',2).last, vault).returns({ something_else: 'ABC' })
        Travis::Vault::Keys::KV2.stubs(:resolve).with(nil, 'another', paths.last.split('/',2).last, vault).returns({ something_else: 'ABC' })
      end

      context 'when path returns value from Vault' do
        it do
          sh.expects(:echo).never
          sh.expects(:export).with('SECRET_THING_MY_KEY', %("MySecretValue"), echo: false, secure: true)
          sh.expects(:export).with('SECRET_THING_SOMETHING_ELSE', %("ABC"), echo: false, secure: true).twice
          data.expects(:vault_secrets=).with(%w[MySecretValue ABC])

          call
        end
      end
    end

    context 'when path does not returns value from Vault' do
      let(:paths) { %w[kv/path/to/something/secret_thing mnt/another/secret_thing] }

      before do
        Travis::Vault::Keys::KV2.stubs(:resolve).with(nil, 'kv', paths.first.split('/',2).last, vault).returns(nil)
        Travis::Vault::Keys::KV2.stubs(:resolve).with(nil, 'mnt', paths.last.split('/',2).last, vault).returns(nil)
      end

      it do
        sh.expects(:export).never
        sh.expects(:echo).with('The value fetched for path/to/something/secret_thing is blank.', ansi: :yellow)
        sh.expects(:echo).with('The value fetched for another/secret_thing is blank.', ansi: :yellow)
        data.expects(:vault_secrets=).never

        call
      end
    end
  end
end
