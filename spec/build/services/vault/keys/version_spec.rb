require 'spec_helper'

describe Travis::Vault::Keys::Version do
  describe '.call' do
    subject(:call) { described_class.call(vault) }

    context 'when kv_api_ver key is there' do
      let(:vault) do
        {
          secrets: [
            'aaa/bbb',
            'ccc',
            { kv_api_ver: 'kv1' },
            'whatever/else/here'
          ]
        }
      end

      it 'uses its value' do
        is_expected.to eq('kv1')
      end
    end

    context 'when kv_api_ver is not there' do
      let(:vault) do
        {
          secrets: %w[aaa/bbb ccc whatever/else/here]
        }
      end

      it 'uses default value' do
        is_expected.to eq('kv2')
      end
    end
  end
end
