# frozen_string_literal: true

require 'spec_helper'

describe Travis::Vcs::Svn::SshKey, :sexp do
  let(:data) { payload_for(payload_name, :ruby, config: {}) }
  let(:sh) { Travis::Shell::Builder.new }
  let(:ssh_key) { described_class.new(sh, Travis::Build::Data.new(data)) }

  describe '#apply' do
    let(:payload_name) { :svn }

    subject { sh.to_sexp }

    before { ssh_key.apply }

    it { is_expected.to include_sexp([:mkdir, '~/.ssh', recursive: true]) }
    it { is_expected.to include_sexp([:file, ['~/.ssh/id_rsa', 'privatekey']]) }
    it { is_expected.to include_sexp([:chmod, [600, '~/.ssh/id_rsa']]) }
    it { is_expected.to include_sexp([:raw, 'eval `ssh-agent` &> /dev/null']) }
    it { is_expected.to include_sexp([:raw, 'ssh-add ~/.ssh/id_rsa &> /dev/null']) }
    it { is_expected.to include_sexp([:file, ['~/.ssh/config', "Host assembla.com\n\tBatchMode yes\n\tStrictHostKeyChecking no\n\tSendEnv REPO_NAME"], append: true]) }
    it { is_expected.to include_sexp([:export, ['REPO_NAME', 'travis-ci-examples^ruby-example']]) }
    it { is_expected.to include_sexp([:file, ['~/.ssh/id_rsa', 'privatekey']]) }
    it { is_expected.to include_sexp([:export, ['SVN_SSH', '"ssh -o SendEnv=REPO_NAME -o StrictHostKeyChecking=no -l svn"']]) }

    context 'when repository is not from Assembla' do
      let(:payload_name) { :svn_non_assembla }

      it { is_expected.to include_sexp([:export, ["REPO_NAME", "ruby-example"]]) }
      it { is_expected.to include_sexp([:file, ['~/.ssh/id_rsa', 'mybuildtoken']]) }
    end
  end
end