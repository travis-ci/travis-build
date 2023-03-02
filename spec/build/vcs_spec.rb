# frozen_string_literal: true

require 'spec_helper'

describe Travis::Vcs do
  describe '#defaults' do
    subject { described_class.defaults(server_type) }

    context 'when server_type is subversion' do
      let(:server_type) { 'subversion' }

      it 'returns svn defaults' do
        expect(subject).to eq(Travis::Vcs::Svn::DEFAULTS)
      end
    end

    context 'when server_type is git' do
      let(:server_type) { 'git' }

      it 'returns svn defaults' do
        expect(subject).to eq(Travis::Vcs::Git::DEFAULTS)
      end
    end
  end
end