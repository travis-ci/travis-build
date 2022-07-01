require 'spec_helper'

describe Travis::Vault::BuildPaths do
  describe '#build' do
    subject(:build) { described_class.new(secrets).build }

    context 'when everything is valid - some duplicates' do
      let(:secrets) do
        [
          {
            namespace: [
              {name: 'ns1'},
              'project_id/secret_key',
              'project_id/secret_key2'
            ]
          },
          {
            namespace: [
              {name: 'ns2'},
              'project_id2/secret_key',
              'project_id2/secret_key2'
            ]
          },
          'ns1/project_id/secret_key',
          'ns1/project_id/secret_key2',
          'ns2/project_id/secret_key',
          'ns2/project_id/secret_key2',
        ]
      end

      it 'removes duplicates - it leaves only last secret_key and secret_key2  -
          it is connected as env variables are defined - uses only last element of a path.' do
        is_expected.to eq(%w[ns2/project_id/secret_key2 ns2/project_id/secret_key])
      end
    end

    context 'when everything is valid - no duplicates' do
      let(:secrets) do
        [
          {
            namespace: [
              {name: 'ns1'},
              'project_id/secret_key_a',
              'project_id/secret_key_b'
            ]
          },
          {
            namespace: [
              {name: 'ns2'},
              'project_id2/secret_key_c',
              'project_id2/secret_key2_d'
            ]
          },
          'ns1/project_id/secret_key_e',
          'ns1/project_id/secret_key2_f',
          'ns2/project_id/secret_key_g',
          'ns2/project_id/secret_key2_h',
        ]
      end

      it do
        is_expected.to eq(%w[ns2/project_id/secret_key2_h ns2/project_id/secret_key_g ns1/project_id/secret_key2_f ns1/project_id/secret_key_e ns2/project_id2/secret_key2_d ns2/project_id2/secret_key_c ns1/project_id/secret_key_b ns1/project_id/secret_key_a])
      end
    end

    context 'when namespace key is not a namespace key' do
      let(:secrets) do
        [
          {
            collection: [
              {name: 'ns1'},
              'project_id/secret_key_a',
              'project_id/secret_key_b'
            ]
          },
          {
            namespace: [
              {name: 'ns2'},
              'project_id2/secret_key_c',
              'project_id2/secret_key2_d'
            ]
          }
        ]
      end

      it 'ignores unknown key' do
        is_expected.to eq(%w[ns2/project_id2/secret_key2_d ns2/project_id2/secret_key_c])
      end
    end

    context 'when namespace key is not a namespace key' do
      let(:secrets) do
        [
          {
            namespace: %w[project_id/secret_key_a project_id/secret_key_b]
          },
          {
            namespace: [
              {name: 'ns2'},
              'project_id2/secret_key_c',
              'project_id2/secret_key2_d'
            ]
          }
        ]
      end

      it 'is fine without namespace' do
        is_expected.to eq(%w[ns2/project_id2/secret_key2_d ns2/project_id2/secret_key_c project_id/secret_key_b project_id/secret_key_a])
      end
    end
  end
end

