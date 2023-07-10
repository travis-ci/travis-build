# frozen_string_literal: true

require 'spec_helper'

describe Travis::Vcs::Svn::Clone, :sexp do
  let(:data) { payload_for(payload_name, :ruby, config: {}) }
  let(:sh) { Travis::Shell::Builder.new }
  let(:clone) { described_class.new(sh, Travis::Build::Data.new(data)) }

  describe '#apply' do
    let(:assembla_checkout_sexp) { [:cmd, 'svn co svn+ssh://assembla.com/branches/main ruby-example', retry: true] }
    let(:update_sexp) { [:cmd, 'svn update -r 9500504'] }
    let(:payload_name) { :svn }

    subject { sh.to_sexp }

    before { clone.apply }

    it { is_expected.to include_sexp(assembla_checkout_sexp) }
    it { is_expected.to include_sexp(update_sexp) }

    context 'when repository is not from Assembla' do
      let(:payload_name) { :svn_non_assembla }

      it { is_expected.to include_sexp([:cmd, 'svn co /branches/main ruby-example', retry: true]) }
      it { is_expected.to include_sexp(update_sexp) }
    end

    context 'when the job is a PR' do
      let(:payload_name) { :svn_pull_request }

      it { is_expected.to include_sexp(assembla_checkout_sexp) }
      it { is_expected.not_to include(update_sexp) }
      it { is_expected.to include_sexp([:cmd, 'svn merge --non-interactive ^/branches/newfeature']) }
    end
  end
end