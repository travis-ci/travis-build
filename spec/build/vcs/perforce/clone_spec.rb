# frozen_string_literal: true

require 'spec_helper'

describe Travis::Vcs::Perforce::Clone, :sexp do
  let(:data) { payload_for(payload_name, :ruby, config: {}) }
  let(:sh) { Travis::Shell::Builder.new }
  let(:clone) { described_class.new(sh, Travis::Build::Data.new(data)) }

  describe '#apply' do
    let(:payload_name) { :perforce }
    let(:key_sexp) { [:cmd, "echo $(p4 info | grep 'Server address:' | cut -d ' ' -f 3- 2>/dev/null)=pubkey:privatekey > /tmp/p4ticket"] }
    let(:tickets_sexp) { [:export, ['P4TICKETS', '/tmp/p4ticket']] }
    let(:client_sexp) { [:cmd, 'p4 -v ssl.client.trust.name=1 client -S //depot/main -o | p4 -v ssl.client.trust.name=1 client -i'] }

    subject { sh.to_sexp }

    before { clone.apply }

    it { is_expected.to include_sexp([:export, ['P4USER', 'pubkey'], echo: true]) }
    it { is_expected.to include_sexp([:export, ['P4CHARSET', 'utf8']]) }
    it { is_expected.to include_sexp([:export, ['P4PORT', 'ssl:perforce.assembla.com']]) }
    it { is_expected.to include_sexp([:cmd, 'p4 trust -y']) }
    it { is_expected.to include_sexp(key_sexp) }
    it { is_expected.to include_sexp(tickets_sexp) }
    it { is_expected.to include_sexp(client_sexp) }
    it { is_expected.to include_sexp([:cmd, 'p4 -v ssl.client.trust.name=1 sync -p']) }
    it { is_expected.to include_sexp([:cd, 'tempdir', echo: true]) }
    it { is_expected.not_to include_sexp([:mkdir, '~/.ssh', recursive: true]) }

    context 'when repository is not from Assembla' do
      let(:payload_name) { :perforce_non_assembla }

      it { is_expected.to include_sexp([:export, ['P4USER', 'travisuser'], echo: true]) }
      it { is_expected.not_to include_sexp(key_sexp) }
      it { is_expected.to include_sexp([:export, ['P4PASSWD', 'mybuildtoken']]) }
      it { is_expected.not_to include_sexp(tickets_sexp) }
    end

    context 'when the job is a PR' do
      let(:payload_name) { :perforce_pull_request }

      it { is_expected.not_to include(client_sexp) }
      it { is_expected.to include_sexp(tickets_sexp) }
      it { is_expected.to include_sexp([:cmd, 'p4 -v ssl.client.trust.name=1 client -S //depot/main -o | p4 -v ssl.client.trust.name=1 client -i']) }
      it { is_expected.to include_sexp([:cmd, 'p4 -v ssl.client.trust.name=1 sync -p']) }
      it { is_expected.to include_sexp([:cmd, 'p4 -v ssl.client.trust.name=1 merge //depot/newfeature/... //depot/main/...']) }
      it { is_expected.to include_sexp([:cmd, 'p4 -v ssl.client.trust.name=1 resolve -am']) }
    end
  end
end