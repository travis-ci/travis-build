require 'spec_helper'

describe Travis::Build::Appliances::VaultConnect do
  let(:instance) { described_class.new }

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

    shared_examples "it won't connect to the vault for given config" do |config|
      before do
        instance.stubs(:config).returns(config)
      end

      it 'sets @vault variable nil' do
        apply?

        expect(instance.instance_variable_get(:@vault)).to eq(nil)
      end

      it 'returns falsey value' do
        is_expected.to be_falsey
      end
    end

    include_examples "it won't connect to the vault for given config", { vault: { secrets: [] } }
    include_examples "it won't connect to the vault for given config", { vault: { secrets: [{ kv_api_ver: 'kv2' }] } }
    include_examples "it won't connect to the vault for given config", { vault:
                                                                           { secrets:
                                                                               [
                                                                                 { kv_api_ver: 'kv2' },
                                                                                 { namespace: { name: 'blah' } }
                                                                               ]
                                                                           }
                                                                        }
  end

  describe 'apply' do
    subject(:apply) { instance.apply }

    before do
      instance.instance_variable_set(:@vault, { token: 'my_token', api_url: 'https://api_url.com' })
    end

    describe 'connection to the vault' do
      let(:sh) do
        stub('sh')
      end

      context 'when it is proper' do
        before do
          Travis::Vault::Connect.stubs(:call)
          instance.stubs(:sh).returns(sh)
        end

        it 'writes the success message, export vault config variables in the console and does not terminates the job' do
          Travis::Vault::Connect.expects(:call).with({ token: 'my_token', api_url: 'https://api_url.com' })
          sh.expects(:echo).with('Connected to Vault instance.', ansi: :green)
          sh.expects(:export).with('VAULT_ADDR', 'https://api_url.com', echo: true, secure: true)
          sh.expects(:export).with('VAULT_TOKEN', 'my_token', echo: true, secure: true)
          sh.expects(:terminate).never

          apply
        end
      end

      context 'when it is not' do
        shared_examples 'it terminates a job with a message for' do |error_class|
          before do
            Travis::Vault::Connect.stubs(:call).raises(error_class)
            instance.stubs(:sh).returns(sh)
          end

          it 'writes the error message in the console and terminates the job' do
            sh.expects(:echo).with("Failed to connect to the Vault instance. Please verify if:\n* The Vault Token is correct (encrypted, not plain text). \n* The Vault Token is not expired. \n* The Vault can accept connections from the Travis CI build job environments (https://docs.travis-ci.com/user/ip-addresses/).", ansi: :red)
            sh.expects(:terminate)

            apply
          end
        end

        include_examples 'it terminates a job with a message for', Travis::Vault::ConnectionError
        include_examples 'it terminates a job with a message for', ArgumentError
        include_examples 'it terminates a job with a message for', URI::InvalidURIError
      end
    end
  end
end
