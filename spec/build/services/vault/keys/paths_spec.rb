require 'spec_helper'

describe Travis::Vault::Keys::Paths do
  describe '.call' do
    let(:call) { described_class.call(vault) }

    let(:build_paths) { stub(call: nil) }

    let(:vault) do
      { secrets:
          [
            'aaa/bbb',
            'ccc',
            { kv_api_ver: 'kv1' },
            'whatever/else/here'
          ]
      }
    end

    it 'passes to BuildPaths initializer everything but not a hash with kv_api_key' do
      Travis::Vault::Keys::BuildPaths.expects(:new).with(%w[aaa/bbb ccc whatever/else/here]).returns(build_paths)
      build_paths.expects(:call)

      call
    end
  end
end
