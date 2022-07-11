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

      before do
        Travis::Vault::Keys::KV2.stubs(:resolve).with(paths.first, vault).returns({ my_key: 'MySecretValue' })
      end

      context 'when path returns value from Vault' do
        it do
          sh.expects(:echo).never
          sh.expects(:export).with('SECRET_THING', "'{\"my_key\":\"MySecretValue\"}'", echo: true, secure: true)

          call
        end
      end

      context 'when path does not returns value from Vault' do

        before do
          Travis::Vault::Keys::KV2.stubs(:resolve).with(paths.first, vault).returns(nil)
        end

        it do
          sh.expects(:export).never
          sh.expects(:echo).with('The value fetched for path/to/something/secret_thing is blank.', ansi: :yellow)

          call
        end
      end

      context 'when data fetched from vault has more then 14 keys' do
        let(:big_data) do
          {
            aaa: '12334',
            bbb: '12342',
            ccc: '2353',
            ddd: '2344',
            eee: 2321,
            fff: 12232,
            ggg: 12334,
            hhh: 856767,
            iii: 23223,
            jjj: 12345,
            kkk: 12356,
            lll: 567768,
            mmm: 5345345,
            nnn: 1233,
            ooo: 32346456
          }
        end

        before do
          Travis::Vault::Keys::KV2.stubs(:resolve).with(paths.first, vault).returns(big_data)
        end

        it { expect { call }.to raise_error(Travis::Vault::RootKeyError) }

        it do
          sh.expects(:export).never
        end
      end
    end
  end
end
