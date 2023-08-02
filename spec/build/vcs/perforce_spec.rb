# frozen_string_literal: true

require 'spec_helper'

describe Travis::Vcs::Perforce, :sexp do
  let(:data) { payload_for(:perforce, :ruby, config: {}) }
  let(:sh) { Travis::Shell::Builder.new }
  let(:perforce) { described_class.new(sh, Travis::Build::Data.new(data)) }

  describe '#checkout' do
    subject { sh.to_sexp }

    before { perforce.checkout }

    it { is_expected.to include_sexp([:export, ['P4USER', 'pubkey'], echo: true]) }
    it { is_expected.to include_sexp([:export, ['P4CHARSET', 'utf8']]) }
    it { is_expected.to include_sexp([:export, ['P4PORT', 'ssl:perforce.assembla.com']]) }
    it { is_expected.to include_sexp([:cmd, 'p4 trust -y']) }
    it { is_expected.to include_sexp([:cmd, "echo $(p4 info | grep 'Server address:' | cut -d ' ' -f 3- 2>/dev/null)=pubkey:privatekey > /tmp/p4ticket"]) }
    it { is_expected.to include_sexp([:export, ['P4TICKETS', '/tmp/p4ticket']]) }
    it { is_expected.to include_sexp([:cmd, 'p4 -v ssl.client.trust.name=1 client -S //depot/main -o | p4 -v ssl.client.trust.name=1 client -i']) }
    it { is_expected.to include_sexp([:cmd, 'p4 -v ssl.client.trust.name=1 sync -p']) }
    it { is_expected.to include_sexp([:cd, 'tempdir', echo: true]) }
    it { is_expected.not_to include_sexp([:mkdir, '~/.ssh', recursive: true]) }
  end
end