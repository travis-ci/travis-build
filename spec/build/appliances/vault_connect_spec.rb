require 'spec_helper'

describe Travis::Build::Appliances::VaultConnect do
  let(:instance) { described_class.new }

  after do
    Travis::Vault::Config.instance.tap do |i|
      i.api_url = nil
      i.token = nil
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

  describe 'apply' do
    subject(:apply) { instance.apply }

    before do
      instance.instance_variable_set(:@vault, { token: 'my_token', api_url: 'https://api_url.com' })
    end

    describe 'setting env variables' do
      before do
        Travis::Vault::Connect.stubs(:call)
        instance.stubs(:sh).returns(Travis::Shell::Builder.new)
      end
      it { expect { apply }.to change { Travis::Vault::Config.instance.token }.from(nil).to('my_token') }

      it { expect { apply }.to change { Travis::Vault::Config.instance.api_url }.from(nil).to('https://api_url.com') }
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

        it 'writes the success message in the console and does not terminates the job' do
          sh.expects(:echo).with('Connected to Vault instance.', ansi: :green)
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
            sh.expects(:echo).with("Failed to connect to the Vault instance. Please verify if:\n* The Vault Token is correct. \n* The Vault token is not expired. \n* The Vault can accept connections from the Travis CI build job environments (https://docs.travis-ci.com/user/ip-addresses/).", ansi: :red)
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