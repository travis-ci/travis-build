require 'spec_helper'

describe Travis::Build::Addons::Artifacts::Validator do
  let(:data)   { Travis::Build::Data.new(payload_for(:push)) }
  let(:config) { { key: 'key', secret: 'secret', bucket: 'bucket', branch: ['master'] } }
  let(:errors) { subject.valid?; subject.errors }
  subject      { described_class.new(data, config) }

  it 'returns true if all is cool' do
    expect(subject).to be_valid
  end

  describe 'request type' do
    it 'returns false for a pull request' do
      data.stubs(:pull_request).returns '123'
      expect(subject).not_to be_valid
    end

    it 'adds an error message about pull requests being rejected' do
      data.stubs(:pull_request).returns '123'
      expect(errors).to eql([described_class::MSGS[:pull_request]])
    end
  end

  describe 'branch configuration' do
    it 'returns true if there are no branches configured' do
      config.delete(:branch)
      expect(subject).to be_valid
    end

    it 'returns true if the configured branches equals the actual branch' do
      config[:branch] = 'master'
      expect(subject).to be_valid
    end

    it 'returns true if the configured branches include the actual branch' do
      config[:branch] = ['master']
      expect(subject).to be_valid
    end

    it 'returns false if the configured branches do not include the actual branch' do
      config[:branch] = ['development']
      expect(subject).not_to be_valid
    end

    it 'adds an error message about the branch being disabled' do
      config[:branch] = ['development']
      expect(errors).to eql([described_class::MSGS[:branch_disabled] % 'master'])
    end
  end
end
